import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

const testKey = 'test-key';

void main() {
  group('initializePointRegistryStunShsp', () {
    setUpAll(() async {
      SingletonManager.instance.destroyAll();
      await initializePointRegistryStunShsp(testKey);
    });

    tearDownAll(() {
      SingletonManager.instance.destroyAll();
    });

    test('registers IStunShspHandler in registry', () {
      expect(
        () => RegistryAccess.getInstance<IStunShspHandler>(testKey),
        returnsNormally,
      );
    });

    test('IStunShspHandler.shspSocket is not null', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.shspSocket, isNotNull);
    });

    test('IStunShspHandler.shspSocket is an IShspSocketWrapper', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.shspSocket, isA<IShspSocketWrapper>());
    });

    test('IStunShspHandler.shspSocket is not closed', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.shspSocket.isClosed, isFalse);
    });

    test('IStunShspHandler.shspSocket.localPort is valid', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('delegateSocket matches shspSocket', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey) as StunShspHandler;
      expect(handler.delegateSocket, same(handler.shspSocket));
    });

    test('IStunShspHandler.stunHandler is not null', () {
      final handler = RegistryAccess.getInstance<IStunShspHandler>(testKey);
      expect(handler.stunHandler, isNotNull);
    });

    test('registers IDualShspSocketMigratable in registry', () {
      expect(
        () => RegistryAccess.getInstance<IDualShspSocketMigratable>(testKey),
        returnsNormally,
      );
    });
  });
}
