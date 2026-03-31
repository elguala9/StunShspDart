import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('initializePointRegistryStunShsp', () {
    late String testKey;
    var testCounter = 0;

    setUp(() {
      // Generate unique key for each test to avoid registry conflicts
      // Use a counter to ensure absolutely unique keys
      testKey = 'test_instance_${testCounter++}_${DateTime.now().microsecondsSinceEpoch}';
      SingletonManager.instance.destroyAll();
    });

    tearDown(() {
      // Clean up singletons after each test
      // Note: Registry cleanup is handled by unique keys
      SingletonManager.instance.destroyAll();
    });

    test('initializes without throwing', () async {
      expect(
        initializePointRegistryStunShsp(testKey),
        completes,
      );
    });

    test('registers IStunShspHandler in registry with given key', () async {
      await initializePointRegistryStunShsp(testKey);

      expect(
        () => RegistryAccess.getInstance<IStunShspHandler>(testKey),
        returnsNormally,
      );
    });

    test('IStunShspHandler is a StunShspHandler instance', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler, isA<StunShspHandler>());
    });

    test('IStunShspHandler is marked as initialized', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.isInitialized, isTrue);
    });

    test('IStunShspHandler.stunHandler is accessible', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.stunHandler, isNotNull);
    });

    test('IStunShspHandler.stunHandler is a StunHandlerBase', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.stunHandler, isA<StunHandlerBase>());
    });

    test('IStunShspHandler.dualShspSocket is accessible', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.dualShspSocket, isNotNull);
    });

    test('IStunShspHandler.dualShspSocket is IDualShspSocketMigratable', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.dualShspSocket, isA<IDualShspSocketMigratable>());
    });

    test('IStunShspHandler.ipv4ShspSocket is accessible', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.ipv4ShspSocket, isNotNull);
    });

    test('IStunShspHandler.ipv4ShspSocket is not closed', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.ipv4ShspSocket.isClosed, isFalse);
    });

    test('IStunShspHandler.ipv4ShspSocket has a valid local port', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.ipv4ShspSocket.localPort, greaterThan(0));
    });

    test('IDualShspSocketMigratable is registered in registry with given key', () async {
      await initializePointRegistryStunShsp(testKey);

      expect(
        () => RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey),
        returnsNormally,
      );
    });

    test('IDualShspSocketMigratable is the same instance in handler', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      final dualSocket = RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      expect(handler.dualShspSocket, same(dualSocket));
    });

    test('stunHandler is a StunHandlerBase instance', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.stunHandler, isA<StunHandlerBase>());
    });

    test('all registered objects are accessible without throwing', () async {
      await initializePointRegistryStunShsp(testKey);

      expect(() {
        RegistryAccess.getInstance<IStunShspHandler>(testKey);
        RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey);
      }, returnsNormally);
    });

    test('handler can call performLocalRequest', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.performLocalRequest(), completes);
    });

    test('handler can call setStunServer', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(
        () => handler.setStunServer('stun.l.google.com', 19302),
        returnsNormally,
      );
    });

    test('handler can call close', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(() => handler.close(), returnsNormally);
    });

    test('IPv6 socket accessibility is consistent with system support', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();

      if (hasIPv6) {
        expect(handler.ipv6ShspSocket, isNotNull);
        expect(handler.ipv6ShspSocket!.isClosed, isFalse);
      } else {
        expect(handler.ipv6ShspSocket, isNull);
      }
    });

    test('dualShspSocket.ipv4Socket matches handler.ipv4ShspSocket', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.dualShspSocket.ipv4Socket, same(handler.ipv4ShspSocket));
    });

    test('multiple registry accesses with same key return same instance', () async {
      await initializePointRegistryStunShsp(testKey);

      final handlers = [
        RegistryAccess.getInstance<IStunShspHandler>(testKey),
        RegistryAccess.getInstance<IStunShspHandler>(testKey),
        RegistryAccess.getInstance<IStunShspHandler>(testKey),
      ];

      expect(handlers[0], same(handlers[1]));
      expect(handlers[1], same(handlers[2]));
    });

    test('stunHandler has dual handler with ipv4Handler', () async {
      await initializePointRegistryStunShsp(testKey);

      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.stunHandler.dualHandler, isNotNull);
      expect(handler.stunHandler.ipv4Handler, isNotNull);
    });

    test('different keys create separate registry instances', () async {
      const key1 = 'instance_1';
      const key2 = 'instance_2';

      await initializePointRegistryStunShsp(key1);
      await initializePointRegistryStunShsp(key2);

      final handler1 = RegistryAccess.getInstance<IStunShspHandler>(key1);
      final handler2 = RegistryAccess.getInstance<IStunShspHandler>(key2);

      expect(handler1, isNot(same(handler2)));
      expect(handler1.ipv4ShspSocket, isNot(same(handler2.ipv4ShspSocket)));
    });

    test('registry instance is separate from DI singleton', () async {
      // Initialize both registry and DI
      await initializePointRegistryStunShsp(testKey);
      SingletonManager.instance.destroyAll();

      // Now initialize DI
      // Note: Can't test both at same time as DI would interfere with registry
      // This test just verifies the registry initialization doesn't auto-register in DI
      expect(
        () => SingletonDIAccess.get<IStunShspHandler>(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
