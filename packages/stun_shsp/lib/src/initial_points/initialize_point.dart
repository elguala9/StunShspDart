// StunHandlerBaseDI is not part of the stun package's public API (not exported
// from package:stun/stun.dart), but we need to reference its concrete type to
// re-register the DI instance under the abstract StunHandlerBase key.
// ignore: implementation_imports
import 'package:stun/src/generated/stun_handler_base_di.dart';
import 'package:stun_shsp/stun_shsp.dart';

Future<void> initializePointStunShsp() async {
  await initializePointDualShsp();
  final dualShspSocketWrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();

  await initialPointStun();

  final ipv4 = dualShspSocketWrapper.ipv4Socket;
  if (ipv4 != null) {
    SingletonDIAccess.addInstance<IShspSocket>(ipv4);
  }

  final stunBase = SingletonDIAccess.get<StunHandlerBaseDI>();
  SingletonDIAccess.addInstanceAs<StunHandlerBase, StunHandlerBaseDI>(stunBase);

  if (ipv4 != null) {
    final wrapper = ipv4 is IShspSocketWrapper ? ipv4 : ShspSocketWrapper(ipv4);
    final handler = StunShspHandler(wrapper);
    SingletonDIAccess.addInstanceAs<IStunShspHandler, StunShspHandler>(handler);
  }
}
