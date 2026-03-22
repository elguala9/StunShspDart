import 'package:singleton_manager/singleton_manager.dart';
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

    // ── IStunShspHandler DI registration ─────────────────────────────────────

    test('registers IStunShspHandler in DI without throwing', () {
      expect(() => SingletonDIAccess.get<IStunShspHandler>(), returnsNormally);
    });

    test('IStunShspHandler instance is a StunShspHandler', () {
      expect(SingletonDIAccess.get<IStunShspHandler>(), isA<StunShspHandler>());
    });

    test('same instance is returned on repeated DI access', () {
      final h1 = SingletonDIAccess.get<IStunShspHandler>();
      final h2 = SingletonDIAccess.get<IStunShspHandler>();
      expect(h1, same(h2));
    });

    // ── StunShspHandler properties ────────────────────────────────────────────

    test('stunHandler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isNotNull);
    });

    test('dualShspSocket is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket, isNotNull);
    });

    test('ipv4ShspSocket is not closed', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('ipv4ShspSocket has a valid local port', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.localPort, greaterThan(0));
    });

    test('dualShspSocket.ipv4Socket matches ipv4ShspSocket', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket.ipv4Socket, same(handler.ipv4ShspSocket));
    });

    // ── IPv6 consistency ──────────────────────────────────────────────────────

    test('IPv6 socket presence is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final handler = SingletonDIAccess.get<IStunShspHandler>();

      if (hasIPv6) {
        expect(handler.ipv6ShspSocket, isNotNull,
            reason: 'IPv6 available: ipv6ShspSocket should be set');
        expect(handler.ipv6ShspSocket!.isClosed, isFalse,
            reason: 'IPv6 socket should not be closed');
      } else {
        expect(handler.ipv6ShspSocket, isNull,
            reason: 'IPv6 unavailable: ipv6ShspSocket should be null');
      }
    });

    // ── StunShspHandler delegates to STUN ─────────────────────────────────────

    test('stunHandler is a DualStunHandler', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isA<DualStunHandler>());
    });

    test('stunHandler.ipv4Handler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      final dual = handler.stunHandler as DualStunHandler;
      expect(dual.ipv4Handler, isNotNull);
    });
  });
}
