// ignore_for_file: avoid_print
import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// StunShspHandler — constructors
// ============================================================================

Future<void> stunShspHandlerConstructorExample() async {
  final socket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  final wrapper = ShspSocketWrapper(socket);
  final handler = StunShspHandler(wrapper);
  print('StunShspHandler created via constructor, port=${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultIpv4Example() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('createDefault(ipv6:false) bound to port ${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultIpv6Example() async {
  final handler = await StunShspHandler.createDefault(ipv6: true);
  print('createDefault(ipv6:true) bound to port ${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultPortExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false, port: 3478);
  print('createDefault(port:3478) bound to port ${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultCodecExample() async {
  final codec = GZipCodec();
  final handler = await StunShspHandler.createDefault(
    ipv6: false,
    compressionCodec: codec,
  );
  print('createDefault with GZipCodec, port=${handler.shspSocket.localPort}');
  handler.close();
}

// ============================================================================
// StunShspHandler — own getters
// ============================================================================

Future<void> stunShspHandlerStunHandlerGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final stun = handler.stunHandler;
  print('stunHandler is ${stun.runtimeType}');
  handler.close();
}

Future<void> stunShspHandlerShspSocketGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final socket = handler.shspSocket;
  print('shspSocket localPort=${socket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerDelegateSocketGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final ds = handler.delegateSocket;
  print('delegateSocket localPort=${ds.localPort}, same as shspSocket=${identical(ds, handler.shspSocket)}');
  handler.close();
}

Future<void> stunShspHandlerDelegateStunHandlerGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final dsh = handler.delegateStunHandler;
  print('delegateStunHandler is ${dsh.runtimeType}, same as stunHandler=${identical(dsh, handler.stunHandler)}');
  handler.close();
}

// ============================================================================
// StunShspHandler — own methods
// ============================================================================

Future<void> stunShspHandlerMigrateSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final oldPort = handler.shspSocket.localPort;
  final newSocket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  handler.migrateSocket(newSocket);
  print('migrateSocket: old port=$oldPort -> new port=${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCloseExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.close();
  print('close() called, isClosed=${handler.shspSocket.isClosed}');
}

Future<void> stunShspHandlerDestroyExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.destroy();
  print('destroy() called, isClosed=${handler.shspSocket.isClosed}');
}

// ============================================================================
// StunShspHandler — IStunHandlerDelegationMixin methods
// ============================================================================

Future<void> stunShspHandlerPerformStunRequestExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final response = await handler.performStunRequest();
  print('performStunRequest: publicIp=${response.publicIp}, publicPort=${response.publicPort}, ipVersion=${response.ipVersion}');
  handler.close();
}

Future<void> stunShspHandlerPerformLocalRequestExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final info = await handler.performLocalRequest();
  print('performLocalRequest: localIp=${info.localIp}, localPort=${info.localPort}');
  handler.close();
}

Future<void> stunShspHandlerPingStunServerExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final alive = await handler.pingStunServer();
  print('pingStunServer: server reachable=$alive');
  handler.close();
}

Future<void> stunShspHandlerSetStunServerExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.setStunServer('stun.l.google.com', 19302);
  print('setStunServer: custom STUN server configured');
  handler.close();
}

Future<void> stunShspHandlerGetSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final rawSocket = handler.getSocket();
  print('getSocket: port=${rawSocket.port}');
  handler.close();
}

Future<void> stunShspHandlerLastStunUpdatedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  await handler.performStunRequest();
  print('lastStunUpdated: ${handler.lastStunUpdated}');
  handler.close();
}

Future<void> stunShspHandlerLastLocalUpdatedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  await handler.performLocalRequest();
  print('lastLocalUpdated: ${handler.lastLocalUpdated}');
  handler.close();
}

Future<void> stunShspHandlerSocketRefreshCallbackExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);

  void onRefresh(StunResponse newResponse, StunResponse? oldResponse) {
    print('addOnSocketRefresh: new port=${newResponse.publicPort}');
  }

  handler.addOnSocketRefresh(onRefresh);
  final newSocket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  handler.migrateSocket(newSocket);
  handler.removeOnSocketRefresh(onRefresh);

  handler.close();
}

// ============================================================================
// StunShspHandler — ShspSocketWrapperDelegationMixin properties / methods
// ============================================================================

Future<void> stunShspHandlerPortExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('port (RawDatagramSocket): ${handler.port}');
  handler.close();
}

Future<void> stunShspHandlerAddressExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('address (RawDatagramSocket): ${handler.address}');
  handler.close();
}

Future<void> stunShspHandlerBroadcastEnabledExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('broadcastEnabled: ${handler.broadcastEnabled}');
  handler.close();
}

Future<void> stunShspHandlerReadEventsEnabledExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('readEventsEnabled: ${handler.readEventsEnabled}');
  handler.close();
}

Future<void> stunShspHandlerWriteEventsEnabledExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('writeEventsEnabled: ${handler.writeEventsEnabled}');
  handler.close();
}

Future<void> stunShspHandlerLocalAddressExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('localAddress: ${handler.localAddress}');
  handler.close();
}

Future<void> stunShspHandlerLocalPortExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('localPort: ${handler.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCompressionCodecExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('compressionCodec: ${handler.compressionCodec.runtimeType}');
  handler.close();
}

Future<void> stunShspHandlerIsClosedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('isClosed (before close): ${handler.isClosed}');
  handler.close();
  print('isClosed (after close): ${handler.isClosed}');
}

Future<void> stunShspHandlerExtractProfileExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final profile = handler.extractProfile();
  print('extractProfile: ${profile.runtimeType}');
  handler.close();
}

Future<void> stunShspHandlerApplyProfileExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final profile = handler.extractProfile();
  handler.applyProfile(profile);
  print('applyProfile: profile reapplied successfully');
  handler.close();
}

Future<void> stunShspHandlerRawSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final raw = handler.socket;
  print('socket (RawDatagramSocket): port=${raw.port}, address=${raw.address}');
  handler.close();
}

Future<void> stunShspHandlerSerializedObjectExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final serialized = handler.serializedObject();
  print('serializedObject: length=${serialized.length}');
  handler.close();
}
