import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/generated/stun_shsp_handler_di.dart';
import 'package:stun_shsp/stun_shsp.dart';


Future<void> initializePointStunShsp() async {
  await initializePointDualShsp();
  final dualShspSocketWrapper = SingletonDIAccess.get<DualShspSocketWrapperDI>();
  await initialPointStunWithSockets(dualShspSocketWrapper.ipv4Socket, ipv6Socket: dualShspSocketWrapper.ipv6Socket);

  final handler = StunShspHandlerDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IStunShspHandler, StunShspHandler>(handler);
}