import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// The subkeys the graph can actually be resolved under on this host:
/// `connectDualShspSockets` leaves `ipv6` unregistered where IPv6 is missing,
/// so asserting it unconditionally would fail for the host, not for the code.
late final List<String> _availableSubkeys;

/// Every type [MainInjectionStunShspPersonalized] is expected to make
/// resolvable, paired with the subkey it lives under.
void main() {
  setUpAll(() async {
    _availableSubkeys = [
      'ipv4',
      if (await AddressUtility.canCreateIPv6Socket()) 'ipv6',
    ];
  });

  group('MainInjectionStunShspPersonalized', () {
    test('resolves the SHSP half of the graph', () async {
      const key = 'personalized_shsp';
      await MainInjectionStunShspPersonalized()
          .registerAllSingletonsStunShspAsync(key: key);

      final registry = RegistryManager.instance;

      // SHSP sockets and their migratable wrappers, per family, each on the
      // raw socket connected for that same subkey.
      for (final subkey in _availableSubkeys) {
        final raw = registry.getInstance<RawDatagramSocket>(
          key: key,
          subkey: subkey,
        );
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
        expect(socket.localPort, equals(raw.port), reason: subkey);
        expect(migratable.isClosed, isFalse, reason: subkey);
        // The wrapper delegates to that very socket, it doesn't own another.
        expect(
          (migratable as ShspSocketMigratable).delegateSocket,
          same(socket),
          reason: subkey,
        );
        expect(
          registry.getInstance<IShspSocket>(key: key, subkey: subkey),
          same(socket),
          reason: subkey,
        );
      }

      final auto = registry.getInstance<IDualShspSocketAuto>(key: key);
      final migratableDual = registry.getInstance<IDualShspSocketMigratable>(
        key: key,
      );
      final ipv4Wrapper = registry.getInstance<IShspSocketMigratable>(
        key: key,
        subkey: 'ipv4',
      );
      expect(auto.getSocketMigratable(InternetAddressType.IPv4),
          same(ipv4Wrapper));
      expect(migratableDual.getSocketMigratable(InternetAddressType.IPv4),
          same(ipv4Wrapper));
      // The SHSP socket registry resolves too, and reports the families this
      // host actually got — which is what the graph was wired with.
      final socketRegistry = registry.getInstance<IRegistryShspSocket>(
        key: key,
      );
      expect(
        socketRegistry.initialize(migratableDual),
        _availableSubkeys.contains('ipv6')
            ? ReturnTypeInitialization.ipv4and6
            : ReturnTypeInitialization.ipv4only,
      );
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

      for (final subkey in _availableSubkeys) {
        final raw = registry.getInstance<RawDatagramSocket>(
          key: key,
          subkey: subkey,
        );
        final handler = registry.getInstance<IStunHandler>(
          key: key,
          subkey: subkey,
        );
        addTearDown(handler.close);
        final migratableHandler = registry.getInstance<IStunHandlerMigratable>(
          key: key,
          subkey: subkey,
        );
        addTearDown(migratableHandler.close);

        // Both STUN representations sit on the socket of that same subkey —
        // the one the SHSP wiring bound, not a new one.
        expect(handler.getSocket(), same(raw), reason: subkey);
        expect(migratableHandler.getSocket(), same(raw), reason: subkey);
      }

      final stunIpv4 = registry.getInstance<IStunHandler>(
        key: key,
        subkey: 'ipv4',
      );
      expect(stunIpv4.getSocket(), same(rawIpv4));

      final dualStun = registry.getInstance<IDualStunHandler>(key: key);
      addTearDown(dualStun.close);
      expect(dualStun.ipv4Handler, same(stunIpv4));
      expect(
        registry
            .getInstance<IDualStunHandlerMigratable>(key: key)
            .getSocket(type: InternetAddressType.IPv4),
        same(rawIpv4),
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
      expect(
        dual.ipv4StunShspHandler!.shspSocket,
        same(
          RegistryManager.instance.getInstance<IShspSocketMigratable>(
            key: key,
            subkey: 'ipv4',
          ),
        ),
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
      }.entries.where((e) => _availableSubkeys.contains(e.key))) {
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
