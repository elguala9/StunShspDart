import 'package:stun_shsp/stun_shsp.dart';

/// Connects `StunShspHandler` under the `'ipv4'`/`'ipv6'` subkeys.
///
/// Same situation as `connectShspSocketMigratableSubkeys` in the SHSP
/// package: `StunShspHandler` has no fixed subkey of its own and nothing else
/// in the graph demands `IStunShspHandler` under `'ipv4'`/`'ipv6'`, so the
/// generator can only connect it once, under the default subkey. Its socket
/// parameter resolves via `@Subkey.inherited()`, which is what makes one
/// registration per family meaningful in the first place.
void connectStunShspHandlerSubkeys({String key = 'default'}) {
  RegistryManager.instance
    ..connectInstance<IStunShspHandler, StunShspHandler>(
      () => StunShspHandler.dependencyInjectionFactory(key: key, subkey: 'ipv4'),
      key: key,
      subkey: 'ipv4',
    )
    ..connectInstance<IStunShspHandler, StunShspHandler>(
      () => StunShspHandler.dependencyInjectionFactory(key: key, subkey: 'ipv6'),
      key: key,
      subkey: 'ipv6',
    );
}

/// Host of the three graphs this package sits on: it wires SHSP, then STUN,
/// then its own singletons, all under one key.
///
/// - `beforeRegisterAllSingletonsStunShspAsync` runs `DualShspInjector`, which
///   binds the ipv4/ipv6 `RawDatagramSocket`s (`connectDualShspSockets`) and
///   connects the SHSP sockets and their migratable wrappers.
/// - `beforeRegisterAllSingletonsStunShsp` then runs
///   `registerAllSingletonsStun` and [connectStunShspHandlerSubkeys].
///
/// The raw sockets are deliberately left to the SHSP side: the STUN package's
/// own `DualStunInjector` would bind *new* ones and overwrite them, and the
/// point of this package is that STUN and SHSP share one endpoint. Because
/// they are already connected under the `'ipv4'`/`'ipv6'` subkeys, the
/// `IStunHandler`/`IDualStunHandler` of the STUN graph resolve onto the very
/// same sockets the SHSP graph uses.
///
/// Use the async entry point — [initializeStunShsp] or
/// `registerAllSingletonsStunShspAsync` — since binding sockets is
/// asynchronous. The plain `registerAllSingletonsStunShsp` only connects the
/// synchronous part, and expects the SHSP graph to be wired already.
class StunShspInjector
    with MainInjectionStunMixin, MainInjectionStunShspMixin {
  const StunShspInjector();

  @override
  Future<void> beforeRegisterAllSingletonsStunShspAsync({
    String key = 'default',
  }) => const DualShspInjector().registerAllSingletonsShspAsync(key: key);

  @override
  void beforeRegisterAllSingletonsStunShsp({String key = 'default'}) {
    registerAllSingletonsStun(key: key);
    connectStunShspHandlerSubkeys(key: key);
  }
}

/// Wires up everything needed to resolve `IStunShspHandler` (per family) and
/// `IDualStunShspHandler` under [key] — see [StunShspInjector] for what runs
/// in which order.
///
/// Each call is independent, so several graphs can live side by side under
/// different keys:
/// ```dart
/// await initializeStunShsp();
/// final ipv4 = RegistryManager.instance
///     .getInstance<IStunShspHandler>(subkey: 'ipv4');
/// final dual = RegistryManager.instance.getInstance<IDualStunShspHandler>();
/// ```
Future<void> initializeStunShsp({String key = 'default'}) =>
    const StunShspInjector().registerAllSingletonsStunShspAsync(key: key);
