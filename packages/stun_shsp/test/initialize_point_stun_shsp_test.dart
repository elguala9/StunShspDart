import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('initializePointStunShsp — DI registrations', () {
    setUpAll(() async {
      SingletonManager.instance.destroyAll();
      await initializePointStunShsp();
    });

    tearDownAll(() {
      SingletonManager.instance.destroyAll();
    });

    test('registers IStunShspHandler in DI', () {
      expect(
        () => SingletonDIAccess.get<IStunShspHandler>(),
        returnsNormally,
      );
    });

    test('IStunShspHandler is a StunShspHandler', () {
      expect(
        SingletonDIAccess.get<IStunShspHandler>(),
        isA<StunShspHandler>(),
      );
    });

    test('IStunShspHandler.stunHandler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isNotNull);
    });

    test('IStunShspHandler.shspSocket is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket, isNotNull);
    });

    test('IStunShspHandler.shspSocket is IShspSocketWrapper', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket, isA<IShspSocketWrapper>());
    });

    test('IStunShspHandler.shspSocket is not closed', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket.isClosed, isFalse);
    });

    test('IStunShspHandler.shspSocket has a valid local port', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket.localPort, greaterThan(0));
    });

    test('delegateSocket matches shspSocket', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>() as StunShspHandler;
      expect(handler.delegateSocket, same(handler.shspSocket));
    });

    test('registers IShspSocket in DI', () {
      expect(
        () => SingletonDIAccess.get<IShspSocket>(),
        returnsNormally,
      );
    });

    test('IShspSocket is the same instance as DualShspSocketWrapperDI.ipv4Socket',
        () {
      final shspSocket = SingletonDIAccess.get<IShspSocket>();
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      expect(shspSocket, same(wrapper.ipv4Socket));
    });

    test('DualShspSocketWrapperDI is registered in DI', () {
      expect(
        () => SingletonDIAccess.get<DualShspSocketWrapperDI>(),
        returnsNormally,
      );
    });

    test('DualShspSocketWrapperDI.ipv4Socket matches the registered IShspSocket',
        () {
      final socket = SingletonDIAccess.get<IShspSocket>();
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      expect(wrapper.ipv4Socket, same(socket));
    });

    test('ShspSocketWrapper wraps the IShspSocket', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket, isA<ShspSocketWrapper>());
      expect(handler.shspSocket, same(handler.shspSocket));
    });

    test('migrateSocket moves to new socket', () async {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      final newSocket = await ShspSocket.bindDefault(ipv6: false);
      final newPort = newSocket.localPort;
      handler.migrateSocket(newSocket);
      expect(handler.shspSocket.localPort, equals(newPort));
      newSocket.close();
    });

    // IPv6
    test('IPv6 handler socket added via DualShspSocketWrapperDI', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      if (hasIPv6) {
        expect(wrapper.ipv6Socket, isNotNull);
        expect(wrapper.ipv6Socket!.isClosed, isFalse);
      } else {
        expect(wrapper.ipv6Socket, isNull);
      }
    });

    test('DualShspSocketWrapperDI ipv4 and ipv6 are separate for dual-stack',
        () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      expect(wrapper.ipv4Socket, isNotNull);
      if (hasIPv6) {
        expect(wrapper.ipv6Socket, isNotNull);
        expect(wrapper.ipv4Socket, isNot(same(wrapper.ipv6Socket)));
      }
    });

    test('StunHandlerBase is registered in DI', () {
      final stunBase = SingletonDIAccess.get<StunHandlerBase>();
      expect(stunBase, isA<StunHandlerBase>());
    });
  });
}
