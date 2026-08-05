import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Every type [MainInjectionStunShspPersonalized] is expected to make
/// resolvable, paired with the subkey it lives under.
void main() {
  group('MainInjectionStunShspPersonalized', () {
    test('resolves the SHSP half of the graph', () async {
      const key = 'personalized_shsp';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      final registry = RegistryManager.instance;

      // Raw sockets connected by connectSockets().
      expect(
        registry.getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4'),
        isNotNull,
      );
      expect(
        registry.getInstance<RawDatagramSocket>(key: key, subkey: 'ipv6'),
        isNotNull,
      );

      // SHSP sockets and their migratable wrappers, per family.
      for (final subkey in ['ipv4', 'ipv6']) {
        final socket = registry.getInstance<IShspSocket>(
          key: key,
          subkey: subkey,
        );
        final migratable = registry.getInstance<IShspSocketMigratable>(
          key: key,
          subkey: subkey,
        );
        addTearDown(() {
          if (!migratable.isClosed) migratable.destroy();
        });
        expect(socket.isClosed, isFalse, reason: subkey);
        expect(migratable.isClosed, isFalse, reason: subkey);
      }

      expect(registry.getInstance<IDualShspSocketAuto>(key: key), isNotNull);
      expect(
        registry.getInstance<IDualShspSocketMigratable>(key: key),
        isNotNull,
      );
      expect(registry.getInstance<IRegistryShspSocket>(key: key), isNotNull);
    });

    test('resolves the STUN half of the graph on the same sockets', () async {
      const key = 'personalized_stun';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      final registry = RegistryManager.instance;
      final rawIpv4 = registry.getInstance<RawDatagramSocket>(
        key: key,
        subkey: 'ipv4',
      );

      for (final subkey in ['ipv4', 'ipv6']) {
        final handler = registry.getInstance<IStunHandler>(
          key: key,
          subkey: subkey,
        );
        addTearDown(handler.close);
        expect(handler, isNotNull, reason: subkey);

        final migratableHandler = registry.getInstance<IStunHandlerMigratable>(
          key: key,
          subkey: subkey,
        );
        addTearDown(migratableHandler.close);
        expect(migratableHandler, isNotNull, reason: subkey);
      }

      final stunIpv4 = registry.getInstance<IStunHandler>(
        key: key,
        subkey: 'ipv4',
      );
      expect(stunIpv4.getSocket().port, equals(rawIpv4.port));

      final dualStun = registry.getInstance<IDualStunHandler>(key: key);
      addTearDown(dualStun.close);
      expect(dualStun, isNotNull);
      expect(
        registry.getInstance<IDualStunHandlerMigratable>(key: key),
        isNotNull,
      );
    });

    test('resolves IDualStunShspHandler', () async {
      const key = 'personalized_dual';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      final dual = RegistryManager.instance.getInstance<IDualStunShspHandler>(
        key: key,
      );
      addTearDown(() {
        if (!dual.isClosed) dual.destroy();
      });

      expect(dual, isA<DualStunShspHandler>());
      expect(dual.getSocket(InternetAddressType.IPv4), isNotNull);
      expect(dual.ipv4StunShspHandler, isNotNull);
      expect(
        dual.dualStunHandler.ipv4Handler,
        same(dual.ipv4StunShspHandler),
      );
    });

    test('resolves one IStunShspHandler per family, on the right socket',
        () async {
      const key = 'personalized_single';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      final registry = RegistryManager.instance;
      for (final entry in {
        'ipv4': InternetAddressType.IPv4,
        'ipv6': InternetAddressType.IPv6,
      }.entries) {
        final handler = registry.getInstance<IStunShspHandler>(
          key: key,
          subkey: entry.key,
        );
        addTearDown(() {
          if (!handler.isClosed) handler.destroy();
        });

        expect(handler, isA<StunShspHandler>(), reason: entry.key);
        expect(handler.shspSocket.isClosed, isFalse, reason: entry.key);
        expect(handler.getIpVersion(), entry.value, reason: entry.key);
        expect(
          handler.shspSocket,
          same(
            registry.getInstance<IShspSocketMigratable>(
              key: key,
              subkey: entry.key,
            ),
          ),
          reason: entry.key,
        );
      }
    });

    // The generated `registerAllSingletonsStunShsp` also connects
    // `IStunShspHandler` under the default subkey, but its socket resolves via
    // `@Subkey.inherited()` and the SHSP graph only ever connects an
    // `IShspSocketMigratable` per family — so that slot cannot be resolved.
    // The shipped `StunShspInjector` behaves the same way; use a family subkey.
    test('the default-subkey slot has no socket to resolve', () async {
      const key = 'personalized_default_subkey';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      expect(
        () => RegistryManager.instance.getInstance<IStunShspHandler>(key: key),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('two keys give two independent graphs', () async {
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: 'personalized_graph_a');
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: 'personalized_graph_b');

      final registry = RegistryManager.instance;
      final a = registry.getInstance<IDualStunShspHandler>(
        key: 'personalized_graph_a',
      );
      final b = registry.getInstance<IDualStunShspHandler>(
        key: 'personalized_graph_b',
      );
      addTearDown(() {
        if (!a.isClosed) a.destroy();
        if (!b.isClosed) b.destroy();
      });

      expect(
        a.getSocket(InternetAddressType.IPv4)!.localPort,
        isNot(b.getSocket(InternetAddressType.IPv4)!.localPort),
      );
    });
  });
}
