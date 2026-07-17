// ignore_for_file: avoid_print
import 'stun_shsp_handler_example.dart';
import 'dual_stun_shsp_handler_example.dart';
import 'nat_detector_shsp_example.dart';

Future<void> main() async {
  // --- StunShspHandler constructors ---
  print('--- StunShspHandler constructors ---\n');
  await stunShspHandlerConstructorExample();
  await stunShspHandlerCreateDefaultIpv4Example();
  await stunShspHandlerCreateDefaultIpv6Example();
  await stunShspHandlerCreateDefaultPortExample();
  await stunShspHandlerCreateDefaultCodecExample();

  // --- StunShspHandler own getters ---
  print('\n--- StunShspHandler own getters ---\n');
  await stunShspHandlerStunHandlerGetterExample();
  await stunShspHandlerShspSocketGetterExample();
  await stunShspHandlerDelegateSocketGetterExample();
  await stunShspHandlerDelegateStunHandlerGetterExample();

  // --- StunShspHandler own methods ---
  print('\n--- StunShspHandler own methods ---\n');
  await stunShspHandlerMigrateSocketExample();
  await stunShspHandlerCloseExample();
  await stunShspHandlerDestroyExample();

  // --- StunShspHandler IStunHandlerDelegationMixin ---
  print('\n--- StunShspHandler IStunHandlerDelegationMixin ---\n');
  await stunShspHandlerPerformStunRequestExample();
  await stunShspHandlerPerformLocalRequestExample();
  await stunShspHandlerPingStunServerExample();
  await stunShspHandlerSetStunServerExample();
  await stunShspHandlerGetSocketExample();
  await stunShspHandlerLastStunUpdatedExample();
  await stunShspHandlerLastLocalUpdatedExample();
  await stunShspHandlerSocketRefreshCallbackExample();

  // --- StunShspHandler ShspSocketWrapperDelegationMixin ---
  print('\n--- StunShspHandler ShspSocketWrapperDelegationMixin ---\n');
  await stunShspHandlerPortExample();
  await stunShspHandlerAddressExample();
  await stunShspHandlerBroadcastEnabledExample();
  await stunShspHandlerReadEventsEnabledExample();
  await stunShspHandlerWriteEventsEnabledExample();
  await stunShspHandlerLocalAddressExample();
  await stunShspHandlerLocalPortExample();
  await stunShspHandlerCompressionCodecExample();
  await stunShspHandlerIsClosedExample();
  await stunShspHandlerExtractProfileExample();
  await stunShspHandlerApplyProfileExample();
  await stunShspHandlerRawSocketExample();
  await stunShspHandlerSerializedObjectExample();

  // --- DualStunShspHandler constructors ---
  print('\n--- DualStunShspHandler constructors ---\n');
  await dualStunShspHandlerConstructorExample();
  await dualStunShspHandlerCreateDefaultExample();
  await dualStunShspHandlerCreateDefaultPortsExample();
  await dualStunShspHandlerCreateDefaultCodecExample();

  // --- DualStunShspHandler own getters ---
  print('\n--- DualStunShspHandler own getters ---\n');
  await dualStunShspHandlerStunShspGettersExample();
  await dualStunShspHandlerShspSocketGettersExample();
  await dualStunShspHandlerDelegateDualSocketExample();
  await dualStunShspHandlerDelegateDualStunHandlerExample();

  // --- DualStunShspHandler own methods ---
  print('\n--- DualStunShspHandler own methods ---\n');
  await dualStunShspHandlerRefreshSocketIpv4Example();
  await dualStunShspHandlerRefreshSocketIpv6Example();
  await dualStunShspHandlerRefreshSocketsExample();
  await dualStunShspHandlerMigrateSocketIpv4Example();
  await dualStunShspHandlerMigrateSocketIpv6Example();
  await dualStunShspHandlerDestroyExample();

  // --- DualStunShspHandler IDualStunHandlerDelegationMixin ---
  print('\n--- DualStunShspHandler IDualStunHandlerDelegationMixin ---\n');
  await dualStunShspHandlerIpHandlersExample();
  await dualStunShspHandlerSetIpHandlerExample();
  await dualStunShspHandlerClearHandlerExample();
  await dualStunShspHandlerReplaceHandlerExample();
  await dualStunShspHandlerPerformStunRequestExample();
  await dualStunShspHandlerPerformLocalRequestExample();
  await dualStunShspHandlerPingStunServerExample();
  await dualStunShspHandlerGetSocketExample();
  await dualStunShspHandlerSetStunServerExample();
  await dualStunShspHandlerSetStunServerPerProtocolExample();
  await dualStunShspHandlerCloseExample();
  await dualStunShspHandlerLastStunTimestampsExample();
  await dualStunShspHandlerLastLocalTimestampsExample();
  await dualStunShspHandlerLastStunUpdatedExample();
  await dualStunShspHandlerLastLocalUpdatedExample();
  await dualStunShspHandlerInitializeDIExample();

  // --- DualStunShspHandler DualShspSocketWrapperDelegationMixin ---
  print('\n--- DualStunShspHandler DualShspSocketWrapperDelegationMixin ---\n');
  await dualStunShspHandlerRawSocketsExample();
  await dualStunShspHandlerSocketWrappersExample();
  await dualStunShspHandlerSocketImplExample();
  await dualStunShspHandlerExtractProfileExample();
  await dualStunShspHandlerApplyProfileExample();
  await dualStunShspHandlerDualSocketStateExample();
  await dualStunShspHandlerRawSocketExample();
  await dualStunShspHandlerSerializedObjectExample();
  await dualStunShspHandlerCallbacksExample();

  // --- NATDetectorShsp ---
  print('\n--- NATDetectorShsp ---\n');
  await natDetectorShspConstructorExample();
  await natDetectorShspNatShspCompatibilityExample();
}
