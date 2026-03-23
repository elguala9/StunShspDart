// StunHandlerBaseDI is not part of the stun package's public API (not exported
// from package:stun/stun.dart), but we need to reference its concrete type to
// re-register the DI instance under the abstract StunHandlerBase key.
// ignore: implementation_imports
import 'package:stun/src/generated/stun_handler_base_di.dart';
import 'package:stun_shsp/stun_shsp.dart';


Future<void> initializePointStunShsp() async {
  await initializePointDualShsp();
  final dualShspSocketWrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
  await initialPointStunWithSockets(dualShspSocketWrapper.ipv4Socket, ipv6Socket: dualShspSocketWrapper.ipv6Socket);

  // initialPointStunWithSockets registers StunHandlerBaseDI (concrete type) as the key.
  // Re-register the same instance under StunHandlerBase so DI injection works correctly.
  final stunBase = SingletonDIAccess.get<StunHandlerBaseDI>();
  SingletonDIAccess.addInstanceAs<StunHandlerBase, StunHandlerBaseDI>(stunBase);

  final handler = StunShspHandlerDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IStunShspHandler, StunShspHandler>(handler);
}