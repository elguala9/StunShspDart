import 'dart:async';
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Wires the full stun_shsp graph under [key] and resolves it far enough that
/// the ipv4 wrapper, the combined handler and the dual handler actually exist
/// — migration swaps registry entries and repoints wrappers, so the "old"
/// instances must have been built before it runs for the swap to be
/// observable.
Future<
  ({
    IDualStunShspHandler dual,
    IStunShspHandler ipv4Handler,
    IShspSocketMigratable ipv4Wrapper,
    IShspSocket ipv4Socket,
  })
>
_wireGraph(String key) async {
  await initializeStunShsp(key: key);

  final registry = RegistryManager.instance;
  final ipv4Socket = registry.getInstance<IShspSocket>(
    key: key,
    subkey: 'ipv4',
  );
  final ipv4Wrapper = registry.getInstance<IShspSocketMigratable>(
    key: key,
    subkey: 'ipv4',
  );
  final ipv4Handler = registry.getInstance<IStunShspHandler>(
    key: key,
    subkey: 'ipv4',
  );
  final dual = registry.getInstance<IDualStunShspHandler>(key: key);

  addTearDown(() {
    if (!dual.isClosed) dual.destroy();
  });

  return (
    dual: dual,
    ipv4Handler: ipv4Handler,
    ipv4Wrapper: ipv4Wrapper,
    ipv4Socket: ipv4Socket,
  );
}

/// Resolves the ipv6 socket slot, or null when the host has no IPv6 available
/// (`connectDualShspSockets` leaves the subkey unregistered in that case).
IShspSocket? _ipv6SocketOrNull(String key) => RegistryManager.instance
    .getInstanceNullable<IShspSocket>(key: key, subkey: 'ipv6');

void main() {
  group('migrateStunShspSocket', () {
    test('keeps the combined handler and moves it onto the new socket', () async {
      const key = 'stun_shsp_migration_keeps_handler';
      final graph = await _wireGraph(key);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateStunShspSocket(raw, key: key);

      // The combined handler is the live router: same instance before and
      // after, only the socket under it moved.
      expect(migrated, same(graph.ipv4Handler));
      expect(
        RegistryManager.instance.getInstance<IStunShspHandler>(
          key: key,
          subkey: 'ipv4',
        ),
        same(graph.ipv4Handler),
      );
      expect(migrated.localPort, raw.port);
      expect(migrated.getSocket().port, raw.port);
      expect(migrated.isClosed, isFalse);
    });

    test('repoints the registered wrapper and swaps the socket entries', () async {
      const key = 'stun_shsp_migration_swaps_entries';
      final graph = await _wireGraph(key);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateStunShspSocket(raw, key: key);

      final registry = RegistryManager.instance;
      expect(
        registry.getInstance<IShspSocketMigratable>(key: key, subkey: 'ipv4'),
        same(graph.ipv4Wrapper),
      );
      expect(
        registry.getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4'),
        same(raw),
      );
      expect(
        registry.getInstance<IShspSocket>(key: key, subkey: 'ipv4'),
        isNot(same(graph.ipv4Socket)),
      );
      expect(
        (graph.ipv4Wrapper as ShspSocketMigratable).delegateSocket,
        same(registry.getInstance<IShspSocket>(key: key, subkey: 'ipv4')),
      );
      expect(graph.ipv4Socket.isClosed, isTrue);
    });

    test('refreshes the plain IStunHandler entry of the STUN graph', () async {
      const key = 'stun_shsp_migration_refreshes_stun';
      final graph = await _wireGraph(key);

      final registry = RegistryManager.instance;
      final oldStunHandler = registry.getInstance<IStunHandler>(
        key: key,
        subkey: 'ipv4',
      );
      final oldMigratable = registry.getInstance<IStunHandlerMigratable>(
        key: key,
        subkey: 'ipv4',
      );
      final oldPort = oldStunHandler.getSocket().port;

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateStunShspSocket(raw, key: key);

      final newStunHandler = registry.getInstance<IStunHandler>(
        key: key,
        subkey: 'ipv4',
      );
      expect(newStunHandler, isNot(same(oldStunHandler)));
      expect(newStunHandler.getSocket(), same(raw));
      expect(newStunHandler.getSocket().port, isNot(oldPort));
      // The migratable STUN handler stays put, like every other live router:
      // it is the source of truth the new plain handler was seeded from.
      expect(
        registry.getInstance<IStunHandlerMigratable>(key: key, subkey: 'ipv4'),
        same(oldMigratable),
      );
      expect(newStunHandler.getIpVersion(), InternetAddressType.IPv4);
      expect(graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
          raw.port);
    });

    test('skips the STUN entries when only the SHSP half is wired', () async {
      const key = 'stun_shsp_migration_without_stun';
      await const DualShspInjector().registerAllSingletonsShspAsync(key: key);
      connectStunShspHandlerSubkeys(key: key);

      final registry = RegistryManager.instance;
      final handler = registry.getInstance<IStunShspHandler>(
        key: key,
        subkey: 'ipv4',
      );
      addTearDown(() {
        if (!handler.isClosed) handler.destroy();
      });

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateStunShspSocket(raw, key: key);

      expect(migrated, same(handler));
      expect(migrated.localPort, raw.port);
      // Nothing connected IStunHandler under this key, and migration didn't
      // invent an entry for it.
      expect(
        registry.getInstanceNullable<IStunHandler>(key: key, subkey: 'ipv4'),
        isNull,
      );
    });

    test('carries the socket message callbacks over to the new socket', () async {
      const key = 'stun_shsp_migration_carries_profile';
      final graph = await _wireGraph(key);

      final peer = PeerInfo(address: InternetAddress.loopbackIPv4, port: 9601);
      graph.ipv4Handler.setMessageCallback(peer, (_) {});
      final peerKey = MessageCallbackMap.formatKey(peer.address, peer.port);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final migrated = await migrateStunShspSocket(raw, key: key);

      expect(migrated.extractProfile().messageListeners.keys, [peerKey]);
    });

    test('the migrated handler really receives datagrams', () async {
      const key = 'stun_shsp_migration_receives';
      final graph = await _wireGraph(key);

      final sender = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(sender.close);

      final received = Completer<List<int>>();
      final senderPeer = PeerInfo(
        address: InternetAddress.loopbackIPv4,
        port: sender.port,
      );
      // Registered before the swap — it must survive it.
      graph.ipv4Handler.setMessageCallback(senderPeer, (record) {
        if (!received.isCompleted) received.complete(record.msg);
      });

      final raw = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final migrated = await migrateStunShspSocket(raw, key: key);

      sender.send([4, 2], InternetAddress.loopbackIPv4, migrated.localPort!);

      expect(await received.future.timeout(const Duration(seconds: 5)), [4, 2]);
    });

    test('an IPv6 socket migrates the ipv6 slot and leaves ipv4 alone', () async {
      const key = 'stun_shsp_migration_ipv6_slot';
      final graph = await _wireGraph(key);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }
      final ipv4PortBefore = graph.ipv4Handler.localPort;

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
      final migrated = await migrateStunShspSocket(raw, key: key);

      expect(migrated.localPort, raw.port);
      // The dual handler builds its own combined handler per family — a
      // different instance over the very same wrapper, so it follows the swap
      // without being rebuilt.
      expect(graph.dual.ipv6StunShspHandler, isNot(same(migrated)));
      expect(graph.dual.ipv6StunShspHandler!.localPort, raw.port);
      expect(oldIpv6.isClosed, isTrue);
      // ipv4 lives in different registry slots: nothing about it moved.
      expect(graph.ipv4Socket.isClosed, isFalse);
      expect(graph.ipv4Handler.localPort, ipv4PortBefore);
    });

    test('keys are independent — migrating one leaves the other alone', () async {
      const keyA = 'stun_shsp_migration_isolation_a';
      const keyB = 'stun_shsp_migration_isolation_b';
      final graphA = await _wireGraph(keyA);
      final graphB = await _wireGraph(keyB);

      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateStunShspSocket(raw, key: keyA);

      expect(graphA.ipv4Socket.isClosed, isTrue);
      expect(graphB.ipv4Socket.isClosed, isFalse);
      expect(
        RegistryManager.instance.getInstance<IShspSocket>(
          key: keyB,
          subkey: 'ipv4',
        ),
        same(graphB.ipv4Socket),
      );
    });

    test('migrating twice keeps the handler on the newest socket', () async {
      const key = 'stun_shsp_migration_twice';
      final graph = await _wireGraph(key);

      final firstRaw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      await migrateStunShspSocket(firstRaw, key: key);
      final secondRaw = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      await migrateStunShspSocket(secondRaw, key: key);

      expect(graph.ipv4Handler.localPort, secondRaw.port);
      expect(graph.ipv4Handler.getSocket().port, secondRaw.port);
      expect(graph.ipv4Handler.isClosed, isFalse);
    });

    test('throws when nothing is wired under the key', () async {
      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(raw.close);

      expect(
        () => migrateStunShspSocket(raw, key: 'stun_shsp_migration_unwired'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });
  });

  group('migrateStunShspSocketIpv4 / migrateStunShspSocketIpv6', () {
    test('the ipv4 helper binds its own socket and migrates it', () async {
      const key = 'stun_shsp_migration_helper_ipv4';
      final graph = await _wireGraph(key);

      final migrated = await migrateStunShspSocketIpv4(key: key);

      expect(migrated, same(graph.ipv4Handler));
      expect(
        RegistryManager.instance
            .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv4')
            .address
            .type,
        InternetAddressType.IPv4,
      );
      expect(migrated.localPort, isNot(graph.ipv4Socket.localPort));
      expect(graph.ipv4Socket.isClosed, isTrue);
    });

    test('the ipv6 helper binds its own socket and migrates it', () async {
      const key = 'stun_shsp_migration_helper_ipv6';
      await _wireGraph(key);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }

      final migrated = await migrateStunShspSocketIpv6(key: key);

      expect(
        RegistryManager.instance
            .getInstance<RawDatagramSocket>(key: key, subkey: 'ipv6')
            .address
            .type,
        InternetAddressType.IPv6,
      );
      expect(migrated.getIpVersion(), InternetAddressType.IPv6);
      expect(oldIpv6.isClosed, isTrue);
    });
  });

  group('migrateDualStunShspSockets', () {
    test('throws when neither socket is provided', () async {
      const key = 'stun_shsp_dual_migration_no_socket';
      await _wireGraph(key);

      expect(
        () => migrateDualStunShspSockets(key: key),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when ipv4Socket is not bound to an IPv4 address', () async {
      const key = 'stun_shsp_dual_migration_wrong_ipv4';
      final graph = await _wireGraph(key);

      RawDatagramSocket ipv6Raw;
      try {
        ipv6Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
      } catch (_) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }
      addTearDown(ipv6Raw.close);

      expect(
        () => migrateDualStunShspSockets(ipv4Socket: ipv6Raw, key: key),
        throwsA(isA<ArgumentError>()),
      );
      // The bad argument was rejected before anything was migrated.
      expect(graph.ipv4Socket.isClosed, isFalse);
    });

    test('throws when ipv6Socket is not bound to an IPv6 address', () async {
      const key = 'stun_shsp_dual_migration_wrong_ipv6';
      final graph = await _wireGraph(key);

      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(ipv4Raw.close);

      expect(
        () => migrateDualStunShspSockets(ipv6Socket: ipv4Raw, key: key),
        throwsA(isA<ArgumentError>()),
      );
      expect(graph.ipv4Socket.isClosed, isFalse);
    });

    test('throws when no dual handler is registered under the key', () async {
      final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      addTearDown(raw.close);

      expect(
        () => migrateDualStunShspSockets(
          ipv4Socket: raw,
          key: 'stun_shsp_dual_migration_unwired',
        ),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('migrates only the ipv4 slot when ipv6Socket is omitted', () async {
      const key = 'stun_shsp_dual_migration_ipv4_only';
      final graph = await _wireGraph(key);

      final oldIpv6 = _ipv6SocketOrNull(key);
      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      final result = await migrateDualStunShspSockets(
        ipv4Socket: ipv4Raw,
        key: key,
      );

      expect(result.ipv6, isNull);
      expect(result.ipv4, same(graph.ipv4Handler));
      expect(result.ipv4!.localPort, ipv4Raw.port);
      expect(graph.ipv4Socket.isClosed, isTrue);
      if (oldIpv6 != null) {
        expect(oldIpv6.isClosed, isFalse);
      }
    });

    test('migrates both slots in one call', () async {
      const key = 'stun_shsp_dual_migration_both';
      final graph = await _wireGraph(key);

      final oldIpv6 = _ipv6SocketOrNull(key);
      if (oldIpv6 == null) {
        markTestSkipped('No IPv6 available on this host.');
        return;
      }

      final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final ipv6Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);

      final result = await migrateDualStunShspSockets(
        ipv4Socket: ipv4Raw,
        ipv6Socket: ipv6Raw,
        key: key,
      );

      expect(result.ipv4!.localPort, ipv4Raw.port);
      expect(result.ipv6!.localPort, ipv6Raw.port);
      expect(graph.ipv4Socket.isClosed, isTrue);
      expect(oldIpv6.isClosed, isTrue);
      expect(
        graph.dual.getSocket(InternetAddressType.IPv4)!.localPort,
        ipv4Raw.port,
      );
      expect(
        graph.dual.getSocket(InternetAddressType.IPv6)!.localPort,
        ipv6Raw.port,
      );
      // The dual handler itself was never replaced.
      expect(
        RegistryManager.instance.getInstance<IDualStunShspHandler>(key: key),
        same(graph.dual),
      );
    });
  });
}
