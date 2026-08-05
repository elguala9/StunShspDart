import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

Future<int> _findFreePort() async {
  final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final p = s.port;
  s.close();
  return p;
}

void main() {
  group('StunShspHandler.createDefault() — STUN and SHSP', () {
    late StunShspHandler handler;

    tearDown(() {
      handler.close();
    });

    test('SHSP socket binds via createDefault', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('SHSP socket is open after createDefault', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.shspSocket.isClosed, isFalse);
    });

    test('stunHandler is the delegate of the STUN surface', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.stunHandler, same(handler.delegateStunHandler));
      expect(
        handler.stunHandler.getSocket().port,
        equals(handler.shspSocket.localPort),
      );
    });

    test('the STUN half is bound to the SHSP socket', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      expect(handler.getSocket().port, equals(handler.shspSocket.localPort));
      expect(handler.getIpVersion(), InternetAddressType.IPv4);
    });

    test('createDefault with explicit port', () async {
      final freePort = await _findFreePort();
      handler = await StunShspHandler.createDefault(
        ipv6: false,
        port: freePort,
      );
      expect(handler.shspSocket.localPort, equals(freePort));
    });

    test('close() closes the handler', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      handler.close();
      expect(handler.shspSocket.isClosed, isTrue);
    });

    test('destroy() destroys the handler', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      handler.destroy();
      expect(handler.shspSocket.isClosed, isTrue);
    });

    test('shspSocket wraps the bound socket and is the SHSP delegate',
        () async {
      handler = await StunShspHandler.createDefault(ipv6: false);

      expect(handler.delegateSocket, same(handler.shspSocket));
      // A wrapper, not the socket itself: it survives a migration (see the
      // `migrateSocket` test) precisely because it is one level above.
      expect(handler.shspSocket, isA<ShspSocketMigratable>());
      expect(
        (handler.shspSocket as ShspSocketMigratable).delegateSocket.localPort,
        equals(handler.shspSocket.localPort),
      );
    });
  });

  group('StunShspHandler — mixin delegation', () {
    late StunShspHandler handler;

    tearDown(() {
      handler.destroy();
    });

    test('RawDatagramSocket members read through to the socket', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final socket = handler.shspSocket;

      expect(handler.port, equals(socket.localPort));
      expect(handler.address, equals(socket.localAddress));
      // Written through and read back: a getter that returned a constant
      // instead of delegating would not follow.
      handler.broadcastEnabled = true;
      expect(handler.broadcastEnabled, isTrue);
      expect(socket.broadcastEnabled, isTrue);
      handler.broadcastEnabled = false;
      expect(handler.broadcastEnabled, isFalse);

      handler.writeEventsEnabled = true;
      expect(handler.writeEventsEnabled, equals(socket.writeEventsEnabled));
    });

    test('socket properties read through to the socket', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final socket = handler.shspSocket;

      expect(handler.localAddress, equals(socket.localAddress));
      expect(handler.localPort, equals(socket.localPort));
      expect(handler.compressionCodec, same(socket.compressionCodec));
      expect(handler.isClosed, isFalse);

      handler.close();
      expect(handler.isClosed, isTrue);
      expect(socket.isClosed, isTrue);
    });

    test('extractProfile carries the registered callbacks, applyProfile '
        'restores them', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9701);
      final peerKey = MessageCallbackMap.formatKey(peer.address, peer.port);

      handler.setMessageCallback(peer, (_) {});
      final profile = handler.extractProfile();
      expect(profile.messageListeners.keys, contains(peerKey));

      final fresh = await ShspSocket.bindDefault(ipv6: false);
      addTearDown(fresh.close);
      expect(fresh.extractProfile().messageListeners, isEmpty);

      fresh.applyProfile(profile);
      expect(fresh.extractProfile().messageListeners.keys, contains(peerKey));
    });

    test('migrateSocket moves both halves onto the new socket', () async {
      handler = await StunShspHandler.createDefault(ipv6: false);
      final newSocket = await ShspSocket.bindDefault(ipv6: false);
      handler.migrateSocket(newSocket);

      expect(handler.isClosed, isFalse);
      expect(handler.localPort, equals(newSocket.localPort));
      // The STUN half was built on the migratable socket, not on the socket
      // behind it, so it follows the swap.
      expect(handler.getSocket().port, equals(newSocket.localPort));
    });
  });
}
