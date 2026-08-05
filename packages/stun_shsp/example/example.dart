// ignore_for_file: avoid_print
import 'config_example.dart';
import 'dual_stun_shsp_handler_example.dart';
import 'nat_detector_shsp_example.dart';
import 'registry_example.dart';
import 'stun_shsp_handler_example.dart';

Future<void> main() async {
  // --- Configuration ---
  print('--- Configuration ---\n');
  defaultConfigExample();
  initConfigExample();
  nestedDocumentExample();
  jsonConfigExample();
  configExtensionExample();

  // --- StunShspHandler constructors ---
  print('\n--- StunShspHandler constructors ---\n');
  await stunShspHandlerConstructorExample();
  await stunShspHandlerConstructorWithStunServerExample();
  await stunShspHandlerCreateDefaultIpv4Example();
  await stunShspHandlerCreateDefaultIpv6Example();
  await stunShspHandlerCreateDefaultPortExample();
  await stunShspHandlerCreateDefaultFromConfigExample();
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

  // --- StunShspHandler StunHandlerDelegationMixin ---
  print('\n--- StunShspHandler StunHandlerDelegationMixin ---\n');
  await stunShspHandlerPerformStunRequestExample();
  await stunShspHandlerPerformLocalRequestExample();
  await stunShspHandlerPingStunServerExample();
  await stunShspHandlerSetStunServerExample();
  await stunShspHandlerGetSocketExample();
  await stunShspHandlerLastStunUpdatedExample();
  await stunShspHandlerLastLocalUpdatedExample();

  // --- StunShspHandler ShspSocketMigratableDelegationMixin ---
  print('\n--- StunShspHandler ShspSocketMigratableDelegationMixin ---\n');
  await stunShspHandlerPortExample();
  await stunShspHandlerAddressExample();
  await stunShspHandlerSocketFlagsExample();
  await stunShspHandlerLocalAddressExample();
  await stunShspHandlerCompressionCodecExample();
  await stunShspHandlerIsClosedExample();
  await stunShspHandlerProfileExample();
  await stunShspHandlerRawSocketExample();
  await stunShspHandlerSerializedObjectExample();

  // --- DualStunShspHandler constructors ---
  print('\n--- DualStunShspHandler constructors ---\n');
  await dualStunShspHandlerConstructorExample();
  await dualStunShspHandlerFromMigratableExample();
  await dualStunShspHandlerCreateDefaultExample();
  await dualStunShspHandlerCreateDefaultPortsExample();
  await dualStunShspHandlerCreateDefaultCodecExample();

  // --- DualStunShspHandler own getters ---
  print('\n--- DualStunShspHandler own getters ---\n');
  await dualStunShspHandlerStunShspGettersExample();
  await dualStunShspHandlerSocketGettersExample();
  await dualStunShspHandlerDualStunHandlerExample();

  // --- DualStunShspHandler own methods ---
  print('\n--- DualStunShspHandler own methods ---\n');
  await dualStunShspHandlerRefreshSocketExample();
  await dualStunShspHandlerRefreshSocketsExample();
  await dualStunShspHandlerMigrateSocketIpv4Example();
  await dualStunShspHandlerMigrateSocketExample();
  await dualStunShspHandlerCloseExample();
  await dualStunShspHandlerDestroyExample();

  // --- DualStunShspHandler DualStunHandlerDelegationMixin ---
  print('\n--- DualStunShspHandler DualStunHandlerDelegationMixin ---\n');
  await dualStunShspHandlerPerformStunRequestExample();
  await dualStunShspHandlerPerformLocalRequestExample();
  await dualStunShspHandlerPingStunServerExample();
  await dualStunShspHandlerSetStunServerExample();
  await dualStunShspHandlerHandlerSlotsExample();
  await dualStunShspHandlerTimestampsExample();

  // --- DualStunShspHandler as a dual SHSP socket ---
  print('\n--- DualStunShspHandler as a dual SHSP socket ---\n');
  await dualStunShspHandlerSendToExample();
  await dualStunShspHandlerProfileExample();
  await dualStunShspHandlerSerializedObjectExample();
  await dualStunShspHandlerCallbacksExample();

  // --- Dependency injection / registry ---
  print('\n--- Dependency injection / registry ---\n');
  await initializeStunShspExample();
  await sharedGraphsExample();
  await stunShspInjectorExample();
  await connectStunShspHandlerSubkeysExample();
  await multipleGraphsExample();

  // --- NATDetectorShsp ---
  print('\n--- NATDetectorShsp ---\n');
  await natDetectorShspConstructorExample();
  await natDetectorShspFromConfigExample();
  await natDetectorShspOnHandlerSocketExample();
  await natDetectorShspNatShspCompatibilityExample();
}
