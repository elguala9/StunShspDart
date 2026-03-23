import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('initializePointStunShsp', () {
    setUpAll(() async {
      SingletonManager.instance.destroyAll();
      await initializePointStunShsp();
    });

    tearDownAll(() {
      SingletonManager.instance.destroyAll();
    });

    // ── DI: IDualShspSocketMigratable ────────────────────────────────────────

    test('registers IDualShspSocketMigratable in DI', () {
      expect(() => SingletonDIAccess.get<IDualShspSocketMigratable>(), returnsNormally);
    });

    test('IDualShspSocketMigratable is a DualShspSocket', () {
      expect(SingletonDIAccess.get<IDualShspSocketMigratable>(), isA<DualShspSocket>());
    });

    test('ipv4Socket is not closed', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket.isClosed, isFalse);
    });

    test('ipv4Socket has an assigned local port', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket.localPort, greaterThan(0));
    });

    // ── DI: DualShspSocketWrapperDI ──────────────────────────────────────────

    test('registers DualShspSocketWrapperDI in DI', () {
      expect(
        () => SingletonDIAccess.get<DualShspSocketWrapperDI>(),
        returnsNormally,
      );
    });

    test('DualShspSocketWrapperDI delegates to the registered IDualShspSocketMigratable', () {
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(wrapper.ipv4Socket, same(dual.ipv4Socket));
    });

    // ── DI: RegistryShspSocket ───────────────────────────────────────────────

    test('registers RegistryShspSocket in DI', () {
      expect(
        () => SingletonDIAccess.get<RegistryShspSocket>(),
        returnsNormally,
      );
    });

    test('RegistryShspSocket contains SocketType.ipv4', () {
      final reg = SingletonDIAccess.get<RegistryShspSocket>();
      expect(reg.contains(SocketType.ipv4), isTrue);
    });

    test('RegistryShspSocket ipv4 socket matches IDualShspSocketMigratable.ipv4Socket', () {
      final reg = SingletonDIAccess.get<RegistryShspSocket>();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(reg.getInstance(SocketType.ipv4), same(dual.ipv4Socket));
    });

    // ── DI: IDualStunHandler ─────────────────────────────────────────────────

    test('registers IDualStunHandler in DI', () {
      expect(() => SingletonDIAccess.get<IDualStunHandler>(), returnsNormally);
    });

    test('IDualStunHandler is a DualStunHandler', () {
      expect(SingletonDIAccess.get<IDualStunHandler>(), isA<DualStunHandler>());
    });

    test('IDualStunHandler.ipv4Handler is not null', () {
      final stun = SingletonDIAccess.get<IDualStunHandler>();
      expect(stun.ipv4Handler, isNotNull);
    });

    // ── IPv6 coerenza ────────────────────────────────────────────────────────

    test('IPv6 SHSP registration is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      final reg = SingletonDIAccess.get<RegistryShspSocket>();

      if (hasIPv6) {
        expect(dual.ipv6Socket, isNotNull,
            reason: 'IPv6 available: dualSocket.ipv6Socket should be set');
        expect(reg.contains(SocketType.ipv6), isTrue,
            reason: 'IPv6 available: registry should contain SocketType.ipv6');
        expect(reg.getInstance(SocketType.ipv6), same(dual.ipv6Socket),
            reason: 'registry ipv6 socket should match dualSocket.ipv6Socket');
      } else {
        expect(dual.ipv6Socket, isNull,
            reason: 'IPv6 unavailable: dualSocket.ipv6Socket should be null');
        expect(reg.contains(SocketType.ipv6), isFalse,
            reason: 'IPv6 unavailable: registry should not contain SocketType.ipv6');
      }
    });

    test('IPv6 STUN handler is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final stun = SingletonDIAccess.get<IDualStunHandler>();

      if (hasIPv6) {
        expect(stun.ipv6Handler, isNotNull,
            reason: 'IPv6 available: ipv6Handler should be set');
      } else {
        expect(stun.ipv6Handler, isNull,
            reason: 'IPv6 unavailable: ipv6Handler should be null');
      }
    });

    // ── DI: IStunShspHandler ──────────────────────────────────────────────────

    test('registers IStunShspHandler in DI without throwing', () {
      expect(() => SingletonDIAccess.get<IStunShspHandler>(), returnsNormally);
    });

    test('IStunShspHandler is a StunShspHandler', () {
      expect(SingletonDIAccess.get<IStunShspHandler>(), isA<StunShspHandler>());
    });

    test('same IStunShspHandler instance returned on repeated access', () {
      final h1 = SingletonDIAccess.get<IStunShspHandler>();
      final h2 = SingletonDIAccess.get<IStunShspHandler>();
      expect(h1, same(h2));
    });

    test('IStunShspHandler.stunHandler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isNotNull);
    });

    test('IStunShspHandler.dualShspSocket is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket, isNotNull);
    });

    test('IStunShspHandler.ipv4ShspSocket is not closed', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('IStunShspHandler.ipv4ShspSocket has a valid local port', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.localPort, greaterThan(0));
    });

    test('IStunShspHandler.dualShspSocket.ipv4Socket matches ipv4ShspSocket', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket.ipv4Socket, same(handler.ipv4ShspSocket));
    });

    test('IStunShspHandler IPv6 socket consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final handler = SingletonDIAccess.get<IStunShspHandler>();

      if (hasIPv6) {
        expect(handler.ipv6ShspSocket, isNotNull,
            reason: 'IPv6 available: ipv6ShspSocket should be set');
        expect(handler.ipv6ShspSocket!.isClosed, isFalse);
      } else {
        expect(handler.ipv6ShspSocket, isNull,
            reason: 'IPv6 unavailable: ipv6ShspSocket should be null');
      }
    });

    test('IStunShspHandler.stunHandler is a StunHandlerBase', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isA<StunHandlerBase>());
    });

    test('IStunShspHandler.stunHandler.dualHandler is a DualStunHandler', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler.dualHandler, isA<DualStunHandler>());
    });

    test('IStunShspHandler.stunHandler.ipv4Handler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler.ipv4Handler, isNotNull);
    });
  });

  // ── Migrate sockets ────────────────────────────────────────────────────────
  //
  // Each test in this group has a fresh initializePointStunShsp() so migrations
  // from one test don't bleed into the next.

  group('migrate sockets', () {
    late IStunShspHandler handler;

    setUp(() async {
      SingletonManager.instance.destroyAll();
      await initializePointStunShsp();
      handler = SingletonDIAccess.get<IStunShspHandler>();
    });

    tearDown(() {
      SingletonManager.instance.destroyAll();
    });

    // ── IPv4 migrate ───────────────────────────────────────────────────────────

    test('migrateSocketIpv4: ipv4ShspSocket.localPort reflects new socket', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      final expectedPort = newSocket.localPort!;

      handler.migrateSocketIpv4(newSocket);

      expect(handler.ipv4ShspSocket.localPort, equals(expectedPort));
    });

    test('migrateSocketIpv4: dualShspSocket.ipv4Socket.localPort reflects new socket', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      final expectedPort = newSocket.localPort!;

      handler.migrateSocketIpv4(newSocket);

      expect(handler.dualShspSocket.ipv4Socket.localPort, equals(expectedPort));
    });

    test('migrateSocketIpv4: socket port is exactly the new socket port', () async {
      final originalPort = handler.ipv4ShspSocket.localPort!;
      final fixedPort = (originalPort % 60000) + 2000;

      ShspSocket? newSocket;
      int? chosenPort;
      for (var candidate = fixedPort; candidate < fixedPort + 10; candidate++) {
        if (candidate == originalPort) continue;
        try {
          newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, candidate);
          chosenPort = candidate;
          break;
        } catch (_) {}
      }

      newSocket ??= await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      chosenPort ??= newSocket.localPort!;

      handler.migrateSocketIpv4(newSocket);

      expect(handler.ipv4ShspSocket.localPort, equals(chosenPort),
          reason: 'after migration the handler must use the new socket port');
    });

    test('migrateSocketIpv4: socket is still open after migrate', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);

      handler.migrateSocketIpv4(newSocket);

      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('migrateSocketIpv4 twice: last socket port wins', () async {
      final first = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      final second = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
      final expectedPort = second.localPort!;

      handler.migrateSocketIpv4(first);
      handler.migrateSocketIpv4(second);

      expect(handler.ipv4ShspSocket.localPort, equals(expectedPort));
    });

    // ── IPv6 migrate ───────────────────────────────────────────────────────────

    test('migrateSocketIpv6: ipv6ShspSocket.localPort reflects new socket', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      if (!hasIPv6) return;

      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
      final expectedPort = newSocket.localPort!;

      handler.migrateSocketIpv6(newSocket);

      expect(handler.ipv6ShspSocket, isNotNull);
      expect(handler.ipv6ShspSocket!.localPort, equals(expectedPort));
    });

    test('migrateSocketIpv6: socket is still open after migrate', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);

      handler.migrateSocketIpv6(newSocket);

      expect(handler.ipv6ShspSocket, isNotNull);
      expect(handler.ipv6ShspSocket!.isClosed, isFalse);
    });

    test('migrateSocketIpv6: dualShspSocket.ipv6Socket.localPort reflects new socket', () async {
      final newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
      final expectedPort = newSocket.localPort!;

      handler.migrateSocketIpv6(newSocket);

      expect(handler.dualShspSocket.ipv6Socket, isNotNull);
      expect(handler.dualShspSocket.ipv6Socket!.localPort, equals(expectedPort));
    });

    test('migrateSocketIpv6: socket port is exactly the new socket port', () async {
      final originalPort = handler.ipv6ShspSocket?.localPort;

      ShspSocket? newSocket;
      int? chosenPort;

      if (originalPort != null) {
        final fixedPort = (originalPort % 60000) + 2000;
        for (var candidate = fixedPort; candidate < fixedPort + 10; candidate++) {
          if (candidate == originalPort) continue;
          try {
            newSocket = await ShspSocket.bind(InternetAddress.anyIPv6, candidate);
            chosenPort = candidate;
            break;
          } catch (_) {}
        }
      }

      newSocket ??= await ShspSocket.bind(InternetAddress.anyIPv6, 0);
      chosenPort ??= newSocket.localPort!;

      handler.migrateSocketIpv6(newSocket);

      expect(handler.ipv6ShspSocket!.localPort, equals(chosenPort),
          reason: 'after migration the handler must use the new IPv6 socket port');
    });
  });

  // ── STUN requests ──────────────────────────────────────────────────────────
  //
  // These tests require network access to reach a public STUN server.

  group('stun requests', () {
    late IStunShspHandler handler;

    setUpAll(() async {
      SingletonManager.instance.destroyAll();
      await initializePointStunShsp();
      handler = SingletonDIAccess.get<IStunShspHandler>();
    });

    tearDownAll(() {
      SingletonManager.instance.destroyAll();
    });

    const repetitions = 3;

    for (var i = 1; i <= repetitions; i++) {
      test('performStunRequest #$i returns a valid response', () async {
        final response = await handler.performStunRequest();

        expect(response.publicIp, isNotEmpty,
            reason: 'publicIp must be a non-empty string');
        expect(response.publicPort, greaterThan(0),
            reason: 'publicPort must be > 0');
        expect(response.transactionId, hasLength(12),
            reason: 'STUN transaction ID must be 12 bytes');
        expect(
          response.ipVersion,
          anyOf(equals(IpVersion.v4), equals(IpVersion.v6)),
          reason: 'ipVersion must be v4 or v6',
        );
      });
    }

    test('performStunRequest returns consistent publicIp across $repetitions calls', () async {
      final responses = await Future.wait([
        for (var _ = 0; _ < repetitions; _++) handler.performStunRequest(),
      ]);

      final firstIp = responses.first.publicIp;
      for (final r in responses) {
        expect(r.publicIp, equals(firstIp),
            reason: 'publicIp must be stable across concurrent calls');
      }
    });

    test('performStunRequest sequential: same publicIp each time', () async {
      final ips = <String>[];
      for (var i = 0; i < repetitions; i++) {
        final r = await handler.performStunRequest();
        ips.add(r.publicIp);
      }
      expect(ips.toSet(), hasLength(1),
          reason: 'publicIp must not change across sequential calls');
    });

    test('performStunRequest sequential: publicPort is always > 0', () async {
      for (var i = 0; i < repetitions; i++) {
        final r = await handler.performStunRequest();
        expect(r.publicPort, greaterThan(0),
            reason: 'call #${i + 1}: publicPort must be > 0');
      }
    });
  });
}
