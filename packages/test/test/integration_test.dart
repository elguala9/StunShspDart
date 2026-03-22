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

    // ── DI: IDualShspSocket ──────────────────────────────────────────────────

    test('registers IDualShspSocket in DI', () {
      expect(() => SingletonDIAccess.get<IDualShspSocket>(), returnsNormally);
    });

    test('IDualShspSocket is a DualShspSocket', () {
      expect(SingletonDIAccess.get<IDualShspSocket>(), isA<DualShspSocket>());
    });

    test('ipv4Socket is not closed', () {
      final dual = SingletonDIAccess.get<IDualShspSocket>();
      expect(dual.ipv4Socket.isClosed, isFalse);
    });

    test('ipv4Socket has an assigned local port', () {
      final dual = SingletonDIAccess.get<IDualShspSocket>();
      expect(dual.ipv4Socket.localPort, greaterThan(0));
    });

    // ── DI: DualShspSocketWrapperDI ──────────────────────────────────────────

    test('registers DualShspSocketWrapperDI in DI', () {
      expect(
        () => SingletonDIAccess.get<DualShspSocketWrapperDI>(),
        returnsNormally,
      );
    });

    test('DualShspSocketWrapperDI delegates to the registered IDualShspSocket', () {
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      final dual = SingletonDIAccess.get<IDualShspSocket>();
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

    test('RegistryShspSocket ipv4 socket matches IDualShspSocket.ipv4Socket', () {
      final reg = SingletonDIAccess.get<RegistryShspSocket>();
      final dual = SingletonDIAccess.get<IDualShspSocket>();
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
      final dual = SingletonDIAccess.get<IDualShspSocket>();
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
  });
}
