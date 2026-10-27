import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

const int _magicCookie = 0x2112A442;

/// A loopback STUN server that answers every Binding Request with the
/// sender's own address as XOR-MAPPED-ADDRESS, as a real server does.
Future<RawDatagramSocket> _startStunServer() async {
  final server = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((event) {
    if (event != RawSocketEvent.read) return;
    final dg = server.receive();
    if (dg == null || dg.data.length < 20) return;
    server.send(_bindingResponse(dg), dg.address, dg.port);
  });
  return server;
}

Uint8List _bindingResponse(Datagram request) {
  final out = ByteData(32)
    ..setUint16(0, 0x0101) // Binding Success Response
    ..setUint16(2, 12)
    ..setUint32(4, _magicCookie)
    ..setUint16(20, 0x0020) // XOR-MAPPED-ADDRESS
    ..setUint16(22, 8)
    ..setUint8(25, 0x01) // IPv4
    ..setUint16(26, request.port ^ (_magicCookie >> 16));
  final ip = request.address.rawAddress;
  final ipValue = (ip[0] << 24) | (ip[1] << 16) | (ip[2] << 8) | ip[3];
  out.setUint32(28, ipValue ^ _magicCookie);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(8, 20, request.data.sublist(8, 20));
  return bytes;
}

void main() {
  group('StunShspHandler — STUN shares the SHSP socket', () {
    late RawDatagramSocket stunServer;
    late StunShspHandler handler;

    setUp(() async {
      stunServer = await _startStunServer();
      final socket = await ShspSocket.bind(InternetAddress.loopbackIPv4, 0);
      handler = StunShspHandler(
        ShspSocketMigratable(socket),
        address: InternetAddress.loopbackIPv4.address,
        port: stunServer.port,
        timeout: const Duration(seconds: 2),
      );
    });

    tearDown(() {
      handler.close();
      stunServer.close();
    });

    test('a STUN request does not close the SHSP socket', () async {
      final port = handler.shspSocket.localPort;

      await handler.performStunRequest();

      expect(handler.shspSocket.isClosed, isFalse);
      expect(handler.shspSocket.localPort, equals(port));
    });

    test('the answer describes the SHSP socket itself', () async {
      final response = await handler.performStunRequest();

      expect(
        response.publicPort(InternetAddressType.IPv4),
        equals(handler.shspSocket.localPort),
      );
      expect(handler.getSocket().port, equals(handler.shspSocket.localPort));
    });

    test('repeated pings keep the same socket and port', () async {
      final port = handler.shspSocket.localPort;

      for (var i = 0; i < 3; i++) {
        expect(await handler.pingStunServer(), isTrue);
      }

      expect(handler.shspSocket.isClosed, isFalse);
      expect(handler.getSocket().port, equals(port));
      expect(handler.lastStunUpdated, isNotNull);
    });

    test('SHSP still receives datagrams after a STUN request', () async {
      await handler.performStunRequest();
      final sender =
          await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<List<int>>();
      handler.shspSocket.setMessageCallback(
        PeerInfo(address: InternetAddress.loopbackIPv4, port: sender.port),
        (record) => received.complete(record.msg),
      );

      sender.send(
        [1, 2, 3],
        InternetAddress.loopbackIPv4,
        handler.shspSocket.localPort!,
      );

      expect(
        await received.future.timeout(const Duration(seconds: 2)),
        equals([1, 2, 3]),
      );
      sender.close();
    });

    test('times out when the STUN server does not answer', () async {
      stunServer.close();

      await expectLater(
        handler.performStunRequest(),
        throwsA(isA<TimeoutException>()),
      );
      expect(await handler.pingStunServer(), isFalse);
      expect(handler.shspSocket.isClosed, isFalse);
    });

    test('fails without sending when the SHSP socket is closed', () async {
      handler.shspSocket.close();

      await expectLater(
        handler.performStunRequest(),
        throwsA(isA<StateError>()),
      );
      expect(await handler.pingStunServer(), isFalse);
    });
  });
}
