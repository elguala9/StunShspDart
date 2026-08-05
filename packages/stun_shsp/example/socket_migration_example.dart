// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// Socket migration — swapping the bound port under a live handler
// ============================================================================

/// On a single handler: the STUN half is built on the migratable socket, so a
/// swap moves both halves at once and no reference has to be re-handed out.
Future<void> handlerMigrationExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('handler on port ${handler.localPort}');

  final replacement = await ShspSocket.bindDefault(ipv6: false);
  handler.migrateSocket(replacement);

  print('after migration: shsp=${handler.localPort}, '
      'stun=${handler.getSocket().port}');

  handler.destroy();
}

/// On the dual handler: every swap rebuilds the combined handler of that
/// family, so its STUN state never points at a socket that is gone. That
/// includes `refreshSocket`/`refreshSockets`, which rebind and then migrate —
/// they return the *current* socket and do the rebinding in the background, so
/// the new port only shows up on a later read.
Future<void> dualHandlerMigrationExample() async {
  final dual = await DualStunShspHandler.createDefault();
  final before = dual.getSocket(InternetAddressType.IPv4)?.localPort;

  final replacement = await ShspSocket.bindDefault(ipv6: false);
  dual.migrateSocketIpv4(replacement);

  print('ipv4 port $before -> '
      '${dual.getSocket(InternetAddressType.IPv4)?.localPort}');
  print('its combined handler followed: '
      '${dual.ipv4StunShspHandler?.getSocket().port}');

  dual.destroy();
}

/// On a wired graph: the registry-level functions swap the socket *and* the
/// registry entries, the same way `migrateShspSocket`/`migrateStunHandlerSocket`
/// do in the `shsp`/`stun` packages — which is what they delegate to.
///
/// Nothing that routes is replaced: the registered `IStunShspHandler`, its
/// migratable socket and the `IDualStunShspHandler` all stay put, so every
/// holder of them follows the swap.
Future<void> registryMigrationExample() async {
  const key = 'example_migration';
  await initializeStunShsp(key: key);

  final registry = RegistryManager.instance;
  final ipv4 = registry.getInstance<IStunShspHandler>(key: key, subkey: 'ipv4');
  final dual = registry.getInstance<IDualStunShspHandler>(key: key);
  print('ipv4 handler on port ${ipv4.localPort}');

  final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final migrated = await migrateStunShspSocket(raw, key: key);

  print('same handler instance: ${identical(migrated, ipv4)}');
  print('now on port ${ipv4.localPort} (raw ${raw.port})');
  print('the STUN graph moved too: '
      '${registry.getInstance<IStunHandler>(key: key, subkey: 'ipv4').getSocket().port}');
  print('the dual handler follows: '
      '${dual.getSocket(InternetAddressType.IPv4)?.localPort}');

  dual.destroy();
}

/// Both families in one call, and the helpers that bind the socket themselves.
Future<void> dualRegistryMigrationExample() async {
  const key = 'example_migration_dual';
  await initializeStunShsp(key: key);

  final dual = RegistryManager.instance.getInstance<IDualStunShspHandler>(
    key: key,
  );

  final ipv4Raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final result = await migrateDualStunShspSockets(
    ipv4Socket: ipv4Raw,
    key: key,
  );
  print('migrated ipv4 to ${result.ipv4?.localPort}, ipv6 left as it was');

  // Same thing, letting the helper bind the socket.
  final ipv4 = await migrateStunShspSocketIpv4(key: key);
  print('ipv4 rebound to ${ipv4.localPort}');

  dual.destroy();
}

Future<void> main() async {
  await handlerMigrationExample();
  await dualHandlerMigrationExample();
  await registryMigrationExample();
  await dualRegistryMigrationExample();
}
