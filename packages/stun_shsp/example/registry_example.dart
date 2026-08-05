// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// Dependency injection / registry wiring
// ============================================================================

/// The one-call path: binds the ipv4/ipv6 sockets, connects the SHSP graph and
/// then this package's singletons, all under one key.
Future<void> initializeStunShspExample() async {
  await initializeStunShsp(key: 'example');

  final registry = RegistryManager.instance;
  final ipv4 = registry.getInstance<IStunShspHandler>(
    key: 'example',
    subkey: 'ipv4',
  );
  final dual = registry.getInstance<IDualStunShspHandler>(key: 'example');

  print('resolved ipv4 handler on port ${ipv4.localPort}, '
      'dual on ipv4=${dual.getSocket(InternetAddressType.IPv4)?.localPort}');
  print('both share the same socket: '
      '${identical(ipv4.shspSocket, dual.getSocketMigratable(InternetAddressType.IPv4))}');

  dual.destroy();
}

/// The SHSP and STUN graphs are wired too, on the same sockets: the raw
/// ipv4/ipv6 `RawDatagramSocket`s are bound once, by the SHSP side.
Future<void> sharedGraphsExample() async {
  const key = 'example_shared';
  await initializeStunShsp(key: key);

  final registry = RegistryManager.instance;
  final raw = registry.getInstance<RawDatagramSocket>(
    key: key,
    subkey: 'ipv4',
  );
  final shsp = registry.getInstance<IShspSocket>(key: key, subkey: 'ipv4');
  final stun = registry.getInstance<IStunHandler>(key: key, subkey: 'ipv4');
  final dual = registry.getInstance<IDualStunShspHandler>(key: key);

  print('one endpoint: raw=${raw.port} shsp=${shsp.localPort} '
      'stun=${stun.getSocket().port} '
      'combined=${dual.ipv4StunShspHandler?.localPort}');
  dual.destroy();
}

/// The synchronous half on its own, when the application already wired the
/// SHSP graph (and therefore the sockets) itself.
Future<void> stunShspInjectorExample() async {
  const key = 'example_injector';
  await const DualShspInjector().registerAllSingletonsShspAsync(key: key);
  const StunShspInjector().registerAllSingletonsStunShsp(key: key);

  final dual = RegistryManager.instance.getInstance<IDualStunShspHandler>(
    key: key,
  );
  print('StunShspInjector resolved dual handler, '
      'ipv4=${dual.getSocket(InternetAddressType.IPv4)?.localPort}');
  dual.destroy();
}

/// `connectStunShspHandlerSubkeys` on its own, for the per-family handlers
/// without the dual one.
Future<void> connectStunShspHandlerSubkeysExample() async {
  const key = 'example_subkeys';
  await const DualShspInjector().registerAllSingletonsShspAsync(key: key);
  connectStunShspHandlerSubkeys(key: key);

  final registry = RegistryManager.instance;
  final ipv4 = registry.getInstance<IStunShspHandler>(key: key, subkey: 'ipv4');
  final ipv6 = registry.tryGetInstance<IStunShspHandler>(
    key: key,
    subkey: 'ipv6',
  );
  print('ipv4 handler=${ipv4.localPort} (${ipv4.getIpVersion()}), '
      'ipv6 handler=${ipv6?.localPort}');
  ipv4.destroy();
  ipv6?.destroy();
}

/// Two keys, two independent graphs — nothing is shared between them.
Future<void> multipleGraphsExample() async {
  await initializeStunShsp(key: 'example_a');
  await initializeStunShsp(key: 'example_b');

  final registry = RegistryManager.instance;
  final a = registry.getInstance<IDualStunShspHandler>(key: 'example_a');
  final b = registry.getInstance<IDualStunShspHandler>(key: 'example_b');

  print('graph a ipv4=${a.getSocket(InternetAddressType.IPv4)?.localPort}, '
      'graph b ipv4=${b.getSocket(InternetAddressType.IPv4)?.localPort}');
  a.destroy();
  b.destroy();
}
