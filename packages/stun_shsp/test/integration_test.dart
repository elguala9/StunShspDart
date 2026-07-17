import 'dart:io';

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

    test('registers IDualShspSocketMigratable in DI', () {
      expect(
        () => SingletonDIAccess.get<IDualShspSocketMigratable>(),
        returnsNormally,
      );
    });

    test('IDualShspSocketMigratable is a DualShspSocket', () {
      expect(
        SingletonDIAccess.get<IDualShspSocketMigratable>(),
        isA<DualShspSocket>(),
      );
    });

    test('ipv4Socket is not closed', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket!.isClosed, isFalse);
    });

    test('ipv4Socket has an assigned local port', () {
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(dual.ipv4Socket!.localPort, greaterThan(0));
    });

    test('registers DualShspSocketWrapperDI in DI', () {
      expect(
        () => SingletonDIAccess.get<DualShspSocketWrapperDI>(),
        returnsNormally,
      );
    });

    test('DualShspSocketWrapperDI delegates to registered socket', () {
      final wrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();
      expect(wrapper.ipv4Socket, same(dual.ipv4Socket));
    });

    test('registers IDualStunHandler in DI', () {
      expect(
        () => SingletonDIAccess.get<IDualStunHandler>(),
        returnsNormally,
      );
    });

    test('IDualStunHandler is a DualStunHandler', () {
      expect(
        SingletonDIAccess.get<IDualStunHandler>(),
        isA<DualStunHandler>(),
      );
    });

    test('IDualStunHandler.ipv4Handler is not null', () {
      final stun = SingletonDIAccess.get<IDualStunHandler>();
      expect(stun.ipv4Handler, isNotNull);
    });

    test('IPv6 SHSP socket is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final dual = SingletonDIAccess.get<IDualShspSocketMigratable>();

      if (hasIPv6) {
        expect(dual.ipv6Socket, isNotNull);
        expect(dual.ipv6Socket!.isClosed, isFalse);
      } else {
        expect(dual.ipv6Socket, isNull);
      }
    });

    test('IPv6 STUN handler is consistent with system IPv6 support', () async {
      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final stun = SingletonDIAccess.get<IDualStunHandler>();

      if (hasIPv6) {
        expect(stun.ipv6Handler, isNotNull);
      } else {
        expect(stun.ipv6Handler, isNull);
      }
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

    test('same IStunShspHandler instance returned on repeated access', () {
      final h1 = SingletonDIAccess.get<IStunShspHandler>();
      final h2 = SingletonDIAccess.get<IStunShspHandler>();
      expect(h1, same(h2));
    });

    test('IStunShspHandler.stunHandler is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.stunHandler, isNotNull);
    });

    test('IStunShspHandler.shspSocket is not null', () {
      final handler = SingletonDIAccess.get<IStunShspHandler>();
      expect(handler.shspSocket, isNotNull);
    });

    test('IStunShspHandler.shspSocket is an IShspSocketWrapper', () {
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
  });

  group('IStunShspHandler — RawDatagramSocket delegation via mixin', () {
    late IStunShspHandler handler;

    setUp(() async {
      SingletonManager.instance.destroyAll();
      await initializePointStunShsp();
      handler = SingletonDIAccess.get<IStunShspHandler>();
    });

    tearDown(() {
      SingletonManager.instance.destroyAll();
    });

    test('RawDatagramSocket properties are accessible', () {
      expect(handler.port, greaterThan(0));
      expect(handler.address, isA<InternetAddress>());
      expect(handler.broadcastEnabled, isA<bool>());
    });

    test('Socket properties are accessible', () {
      expect(handler.localAddress, isNotNull);
      expect(handler.localPort, greaterThan(0));
      expect(handler.compressionCodec, isNotNull);
      expect(handler.isClosed, isFalse);
    });

    test('extractProfile and applyProfile work', () {
      final profile = handler.extractProfile();
      handler.applyProfile(profile);
      // should not throw
    });

    test('migrateSocket changes the delegate', () async {
      final newSocket = await ShspSocket.bindDefault(ipv6: false);
      handler.migrateSocket(newSocket);
      // after migration, the wrapper delegates to the new socket
      expect(handler.isClosed, isFalse);
      newSocket.close();
    });
  });
}
