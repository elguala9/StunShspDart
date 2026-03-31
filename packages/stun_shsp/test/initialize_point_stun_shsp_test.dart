import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('initializePointStunShsp', () {
    setUp(() {
      // Clean up singletons before each test
      SingletonManager.instance.destroyAll();
    });

    tearDown(() {
      SingletonManager.instance.destroyAll();
    });

    test('initializes without throwing', () async {
      expect(initializePointStunShsp(), completes);
    });

    test('registers IStunShspHandler in DI', () async {
      await initializePointStunShsp();

      expect(
        () => SingletonDIAccess.get<IStunShspHandler>(),
        returnsNormally,
      );
    });

    test('IStunShspHandler is a StunShspHandler instance', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler, isA<StunShspHandler>());
    });

    test('IStunShspHandler is marked as initialized', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.isInitialized, isTrue);
    });

    test('IStunShspHandler.stunHandler is accessible', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isNotNull);
    });

    test('IStunShspHandler.stunHandler is a StunHandlerBase', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isA<StunHandlerBase>());
    });

    test('IStunShspHandler.dualShspSocket is accessible', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket, isNotNull);
    });

    test('IStunShspHandler.dualShspSocket is IDualShspSocketMigratable', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket, isA<IDualShspSocketMigratable>());
    });

    test('IStunShspHandler.ipv4ShspSocket is accessible', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket, isNotNull);
    });

    test('IStunShspHandler.ipv4ShspSocket is not closed', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('IStunShspHandler.ipv4ShspSocket has a valid local port', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.ipv4ShspSocket.localPort, greaterThan(0));
    });

    test('StunHandlerBase is registered in DI', () async {
      await initializePointStunShsp();

      expect(
        () => SingletonDIAccess.get<StunHandlerBase>(),
        returnsNormally,
      );
    });

    test('StunHandlerBase is the same instance in handler', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      final stunBase = SingletonDIAccess.get<StunHandlerBase>();
      expect(handler.stunHandler, same(stunBase));
    });

    test('IDualShspSocketMigratable is registered in DI', () async {
      await initializePointStunShsp();

      expect(
        () => SingletonDIAccess.get<IDualShspSocketMigratable>(),
        returnsNormally,
      );
    });

    test('IDualShspSocketMigratable is the same instance in handler', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      final dualSocket = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(handler.dualShspSocket, same(dualSocket));
    });

    test('IStunShspHandler singleton is returned on repeated access', () async {
      await initializePointStunShsp();

      final handler1 = SingletonDIAccess.get<IStunShspHandler>();
      final handler2 = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler1, same(handler2));
    });

    test('all registered objects are accessible without throwing', () async {
      await initializePointStunShsp();

      expect(() {
        SingletonDIAccess.get<IStunShspHandler>();
        SingletonDIAccess.get<StunHandlerBase>();
        SingletonDIAccess.get<IDualShspSocketMigratable>();
      }, returnsNormally);
    });

    test('handler can call performLocalRequest', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.performLocalRequest(), completes);
    });

    test('handler can call setStunServer', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(
        () => handler.setStunServer('stun.l.google.com', 19302),
        returnsNormally,
      );
    });

    test('handler can call close', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(() => handler.close(), returnsNormally);
    });

    test('IPv6 socket accessibility is consistent with system support', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

      if (hasIPv6) {
        expect(handler.ipv6ShspSocket, isNotNull);
        expect(handler.ipv6ShspSocket!.isClosed, isFalse);
      } else {
        expect(handler.ipv6ShspSocket, isNull);
      }
    });

    test('dualShspSocket.ipv4Socket matches handler.ipv4ShspSocket', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.dualShspSocket.ipv4Socket, same(handler.ipv4ShspSocket));
    });

    test('multiple handler accesses return same singleton', () async {
      await initializePointStunShsp();

      final handlers = [
        SingletonDIAccess.get<IStunShspHandler>(),
        SingletonDIAccess.get<IStunShspHandler>(),
        SingletonDIAccess.get<IStunShspHandler>(),
      ];

      expect(handlers[0], same(handlers[1]));
      expect(handlers[1], same(handlers[2]));
    });

    test('stunHandler has dual handler with ipv4Handler', () async {
      await initializePointStunShsp();

      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler.dualHandler, isNotNull);
      expect(handler.stunHandler.ipv4Handler, isNotNull);
    });
  });
}
