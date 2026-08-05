import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() async {
  final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

  group('DualStunShspHandler.createDefault', () {
    late DualStunShspHandler handler;

    tearDown(() {
      if (!handler.isClosed) handler.destroy();
    });

    test('binds an IPv4 socket and a combined handler for it', () async {
      handler = await DualStunShspHandler.createDefault();

      final socket = handler.getSocket(InternetAddressType.IPv4);
      expect(socket, isNotNull);
      expect(socket!.isClosed, isFalse);
      expect(socket.localPort, greaterThan(0));
      expect(handler.ipv4StunShspHandler, isNotNull);
      expect(handler.ipv4StunShspHandler!.getIpVersion(),
          InternetAddressType.IPv4);
    });

    test('createDefault with explicit ports', () async {
      handler = await DualStunShspHandler.createDefault(ipv4Port: 0);
      expect(handler.getSocket(InternetAddressType.IPv4)!.localPort,
          greaterThan(0));
    });

    test('each combined handler is the dual STUN handler slot', () async {
      handler = await DualStunShspHandler.createDefault();

      expect(handler.dualStunHandler.ipv4Handler,
          same(handler.ipv4StunShspHandler));
      expect(handler.getStunShspHandler(InternetAddressType.IPv4),
          same(handler.ipv4StunShspHandler));
    });

    test('the IPv6 half follows what the host supports', () async {
      handler = await DualStunShspHandler.createDefault();

      if (hasIPv6) {
        expect(handler.getSocket(InternetAddressType.IPv6), isNotNull);
        expect(handler.ipv6StunShspHandler, isNotNull);
        expect(handler.dualStunHandler.ipv6Handler, isNotNull);
      } else {
        expect(handler.ipv6StunShspHandler, isNull);
        expect(handler.dualStunHandler.ipv6Handler, isNull);
      }
    });

    test('ports come from the configuration when not passed', () async {
      initStunShspConfig({
        'socket': {'ipv4Port': 0, 'ipv6Port': 0},
      });
      addTearDown(initStunShspConfig);

      handler = await DualStunShspHandler.createDefault();
      expect(handler.getSocket(InternetAddressType.IPv4)!.localPort,
          greaterThan(0));
    });
  });

  group('DualStunShspHandler — socket migration', () {
    late DualStunShspHandler handler;

    setUp(() async {
      handler = await DualStunShspHandler.createDefault();
    });

    tearDown(() {
      if (!handler.isClosed) handler.destroy();
    });

    test('migrateSocketIpv4 rebuilds the IPv4 combined handler', () async {
      final before = handler.ipv4StunShspHandler;
      final newSocket = await ShspSocket.bindDefault(ipv6: false);

      handler.migrateSocketIpv4(newSocket);

      expect(handler.getSocket(InternetAddressType.IPv4)!.localPort,
          equals(newSocket.localPort));
      expect(handler.ipv4StunShspHandler, isNot(same(before)));
      expect(handler.dualStunHandler.ipv4Handler!.getSocket().port,
          equals(newSocket.localPort));
    });

    test('migrateSocket routes by address family', () async {
      final newSocket = await ShspSocket.bindDefault(ipv6: false);

      handler.migrateSocket(newSocket, InternetAddressType.IPv4);

      expect(handler.getSocket(InternetAddressType.IPv4)!.localPort,
          equals(newSocket.localPort));
    });

    test('the migratable socket keeps its identity across a migration',
        () async {
      final migratable = handler.getSocketMigratable(InternetAddressType.IPv4);
      final newSocket = await ShspSocket.bindDefault(ipv6: false);

      handler.migrateSocketIpv4(newSocket);

      expect(handler.getSocketMigratable(InternetAddressType.IPv4),
          same(migratable));
      expect(handler.ipv4StunShspHandler!.shspSocket, same(migratable));
    });
  });

  group('DualStunShspHandler — lifecycle', () {
    test('close() closes both halves', () async {
      final handler = await DualStunShspHandler.createDefault();
      handler.close();
      expect(handler.isClosed, isTrue);
    });

    test('close(type:) closes only that address family', () async {
      final handler = await DualStunShspHandler.createDefault();
      addTearDown(() {
        if (!handler.isClosed) handler.destroy();
      });
      if (handler.getSocket(InternetAddressType.IPv6) == null) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }

      handler.close(type: InternetAddressType.IPv4);

      expect(handler.getSocket(InternetAddressType.IPv4)!.isClosed, isTrue);
      expect(handler.getSocket(InternetAddressType.IPv6)!.isClosed, isFalse);
      expect(handler.isClosed, isFalse);
    });

    test('destroy() destroys both halves', () async {
      final handler = await DualStunShspHandler.createDefault();
      handler.destroy();
      expect(handler.isClosed, isTrue);
    });
  });
}
