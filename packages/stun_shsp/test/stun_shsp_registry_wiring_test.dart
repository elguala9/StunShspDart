import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Closes whatever [handler] holds, tolerating a family that isn't bound.
void _tearDownDual(IDualStunShspHandler handler) {
  addTearDown(() {
    if (!handler.isClosed) handler.destroy();
  });
}

void main() {
  group('connectStunShspHandlerSubkeys', () {
    test('resolves one handler per family onto the matching socket', () async {
      const key = 'wiring_handler_subkeys';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);
      connectStunShspHandlerSubkeys(key: key);

      final registry = RegistryManager.instance;
      final ipv4 = registry.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv4',
      );
      addTearDown(() {
        if (!ipv4.isClosed) ipv4.destroy();
      });

      final migratable = registry.getInstance<IShspSocketMigratable>(
        key: key,
        subkey: 'ipv4',
      );

      expect(ipv4.shspSocket, same(migratable));
      expect(ipv4.getIpVersion(), InternetAddressType.IPv4);
      // Resolving the same subkey again returns the cached singleton.
      expect(
        registry.getInstance<IStunShspHandler>(key: key, subkey: 'ipv4'),
        same(ipv4),
      );
    });

    test('the ipv6 variant is a different handler on a different socket',
        () async {
      const key = 'wiring_handler_subkeys_ipv6';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);
      connectStunShspHandlerSubkeys(key: key);

      final registry = RegistryManager.instance;
      final ipv6Socket = registry.tryGetInstance<IShspSocketMigratable>(
        key: key,
        subkey: 'ipv6',
      );
      if (ipv6Socket == null) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }

      final ipv4 = registry.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv4',
      );
      final ipv6 = registry.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv6',
      );
      addTearDown(() {
        if (!ipv4.isClosed) ipv4.destroy();
        if (!ipv6.isClosed) ipv6.destroy();
      });

      expect(ipv6, isNot(same(ipv4)));
      expect(ipv6.shspSocket, same(ipv6Socket));
      expect(ipv6.getIpVersion(), InternetAddressType.IPv6);
    });
  });

  group('initializeStunShsp', () {
    test('resolves IDualStunShspHandler over the connected sockets', () async {
      const key = 'wiring_initialize_dual';
      await initializeStunShsp(key: key);

      final registry = RegistryManager.instance;
      final dual = registry.getInstance<IDualStunShspHandler>(key: key);
      _tearDownDual(dual);

      expect(dual, isA<DualStunShspHandler>());
      expect(dual.getSocket(InternetAddressType.IPv4), isNotNull);
      expect(dual.getSocket(InternetAddressType.IPv4)!.isClosed, isFalse);
      expect(dual.getSocket(InternetAddressType.IPv4)!.localPort,
          greaterThan(0));
      expect(dual.ipv4StunShspHandler, isNotNull);
      expect(dual.dualStunHandler.ipv4Handler,
          same(dual.ipv4StunShspHandler));
    });

    test('the single and dual handlers share one socket per family', () async {
      const key = 'wiring_initialize_shared';
      await initializeStunShsp(key: key);

      final registry = RegistryManager.instance;
      final single = registry.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv4',
      );
      final dual = registry.getInstance<IDualStunShspHandler>(key: key);
      _tearDownDual(dual);

      expect(
        single.shspSocket,
        same(dual.getSocketMigratable(InternetAddressType.IPv4)),
      );
    });

    test('resolving the same key twice returns the cached singletons',
        () async {
      const key = 'wiring_initialize_cached';
      await initializeStunShsp(key: key);
      await initializeStunShsp(key: key);

      final registry = RegistryManager.instance;
      final dual = registry.getInstance<IDualStunShspHandler>(key: key);
      _tearDownDual(dual);

      expect(registry.getInstance<IDualStunShspHandler>(key: key), same(dual));
    });

    test('two keys give two independent graphs', () async {
      await initializeStunShsp(key: 'wiring_graph_a');
      await initializeStunShsp(key: 'wiring_graph_b');

      final registry = RegistryManager.instance;
      final a = registry.getInstance<IDualStunShspHandler>(
        key: 'wiring_graph_a',
      );
      final b = registry.getInstance<IDualStunShspHandler>(
        key: 'wiring_graph_b',
      );
      _tearDownDual(a);
      _tearDownDual(b);

      expect(a, isNot(same(b)));
      expect(
        a.getSocket(InternetAddressType.IPv4)!.localPort,
        isNot(b.getSocket(InternetAddressType.IPv4)!.localPort),
      );
    });

    test('the STUN graph of the stun package lands on the same sockets',
        () async {
      const key = 'wiring_initialize_stun_graph';
      await initializeStunShsp(key: key);

      final registry = RegistryManager.instance;
      final dual = registry.getInstance<IDualStunShspHandler>(key: key);
      _tearDownDual(dual);

      final rawIpv4 = registry.getInstance<RawDatagramSocket>(
        key: key,
        subkey: 'ipv4',
      );
      final stunIpv4 = registry.getInstance<IStunHandler>(
        key: key,
        subkey: 'ipv4',
      );
      final dualStun = registry.getInstance<IDualStunHandler>(key: key);

      // The raw sockets come from the SHSP wiring, so the plain STUN handlers
      // share the endpoint with the SHSP sockets instead of binding new ones.
      expect(stunIpv4.getSocket().port, equals(rawIpv4.port));
      expect(
        stunIpv4.getSocket().port,
        equals(dual.getSocket(InternetAddressType.IPv4)!.localPort),
      );
      expect(dualStun.ipv4Handler, isNotNull);
    });

    test('the IPv6 half follows what the host supports', () async {
      const key = 'wiring_initialize_ipv6';
      await initializeStunShsp(key: key);

      final hasIPv6 = await AddressUtility.canCreateIPv6Socket();
      final dual = RegistryManager.instance
          .getInstance<IDualStunShspHandler>(key: key);
      _tearDownDual(dual);

      if (hasIPv6) {
        expect(dual.ipv6StunShspHandler, isNotNull);
        expect(dual.dualStunHandler.ipv6Handler, isNotNull);
      } else {
        expect(dual.ipv6StunShspHandler, isNull);
        expect(dual.dualStunHandler.ipv6Handler, isNull);
      }
    });
  });
}
