// initialPointStunWithSocketsRegistry and IStunHandlerBase are not part of the
// stun package's public API (not exported from package:stun/stun.dart), but we
// need them to wire the registry-based initialization.
// ignore: implementation_imports
import 'package:stun/src/initial_point/initial_point_registry.dart';
// ignore: implementation_imports
import 'package:stun/src/interfaces/i_stun_handler_base.dart';
import 'package:stun_shsp/stun_shsp.dart';

Future<void> initializePointRegistryStunShsp(String key) async {
  await initializePointRegistryAccess(key);
  final dualShspSocketWrapper = RegistryAccess.getInstance<IDualShspSocketWrapper>(key);
  await initialPointStunWithSocketsRegistry(
    key,
    dualShspSocketWrapper.ipv4Socket,
    ipv6Socket: dualShspSocketWrapper.ipv6Socket,
  );

  // initialPointStunWithSocketsRegistry registers _StunHandlerBaseEntry (extends StunHandlerBase)
  // under IStunHandlerBase. Cast to StunHandlerBase for injectDependencies.
  final stunBase = RegistryAccess.getInstance<IStunHandlerBase>(key) as StunHandlerBase;
  final dualSocket = RegistryAccess.getInstance<IDualShspSocketMigratable>(key);
  final handler = StunShspHandler();
  handler.injectDependencies(
    stunHandler: stunBase,
    dualShspSocket: dualSocket,
  );
  RegistryAccess.register<IStunShspHandler>(key, handler);
}
