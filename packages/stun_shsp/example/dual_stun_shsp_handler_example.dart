// ignore_for_file: avoid_print
import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// DualStunShspHandler — constructors
// ============================================================================

Future<void> dualStunShspHandlerConstructorExample() async {
  final ipv4Socket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  final ipv6Socket = await ShspSocket.bindDefault(ipv6: true, port: 0);
  final handler = DualStunShspHandler(ipv4Socket, ipv6Socket);
  print('DualStunShspHandler created via constructor, '
        'IPv4 port=${handler.ipv4ShspSocket.localPort}, '
        'IPv6 port=${handler.ipv6ShspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('createDefault: IPv4 port=${handler.ipv4ShspSocket.localPort}, '
        'IPv6 port=${handler.ipv6ShspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultPortsExample() async {
  final handler = await DualStunShspHandler.createDefault(
    ipv4Port: 5000,
    ipv6Port: 6000,
  );
  print('createDefault(ports): IPv4=${handler.ipv4ShspSocket.localPort}, '
        'IPv6=${handler.ipv6ShspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultCodecExample() async {
  final codec = GZipCodec();
  final handler = await DualStunShspHandler.createDefault(compressionCodec: codec);
  print('createDefault(codec): IPv4 port=${handler.ipv4ShspSocket.localPort}');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — own getters
// ============================================================================

Future<void> dualStunShspHandlerStunShspGettersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ipv4h = handler.ipv4StunShspHandler;
  final ipv6h = handler.ipv6StunShspHandler;
  print('ipv4StunShspHandler port=${ipv4h.shspSocket.localPort}');
  print('ipv6StunShspHandler port=${ipv6h.shspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerShspSocketGettersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ipv4s = handler.ipv4ShspSocket;
  final ipv6s = handler.ipv6ShspSocket;
  print('ipv4ShspSocket port=${ipv4s.localPort}');
  print('ipv6ShspSocket port=${ipv6s.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerDelegateDualSocketExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ds = handler.delegateDualSocket;
  print('delegateDualSocket ipv4 closed=${ds.ipv4Socket?.isClosed}, '
        'ipv6 closed=${ds.ipv6Socket?.isClosed}');
  handler.destroy();
}

Future<void> dualStunShspHandlerDelegateDualStunHandlerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final dsh = handler.delegateDualStunHandler;
  print('delegateDualStunHandler ipv4Handler present=${dsh.ipv4Handler != null}');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — own methods
// ============================================================================

Future<void> dualStunShspHandlerRefreshSocketIpv4Example() async {
  final handler = await DualStunShspHandler.createDefault();
  final oldPort = handler.ipv4ShspSocket.localPort;
  final newSocket = handler.refreshSocketIpv4();
  print('refreshSocketIpv4: old=$oldPort new=${newSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerRefreshSocketIpv6Example() async {
  final handler = await DualStunShspHandler.createDefault();
  final oldPort = handler.ipv6ShspSocket.localPort;
  final newSocket = handler.refreshSocketIpv6();
  print('refreshSocketIpv6: old=$oldPort new=${newSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerRefreshSocketsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final sockets = handler.refreshSockets();
  print('refreshSockets: ipv4 port=${sockets.ipv4SocketImpl?.localPort}, '
        'ipv6 port=${sockets.ipv6SocketImpl?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerMigrateSocketIpv4Example() async {
  final handler = await DualStunShspHandler.createDefault();
  final oldPort = handler.ipv4ShspSocket.localPort;
  final newSocket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  handler.migrateSocketIpv4(newSocket);
  print('migrateSocketIpv4: old=$oldPort new=${handler.ipv4ShspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerMigrateSocketIpv6Example() async {
  final handler = await DualStunShspHandler.createDefault();
  final oldPort = handler.ipv6ShspSocket.localPort;
  final newSocket = await ShspSocket.bindDefault(ipv6: true, port: 0);
  handler.migrateSocketIpv6(newSocket);
  print('migrateSocketIpv6: old=$oldPort new=${handler.ipv6ShspSocket.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerDestroyExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.destroy();
  print('destroy: ipv4 closed=${handler.ipv4ShspSocket.isClosed}, '
        'ipv6 closed=${handler.ipv6ShspSocket.isClosed}');
}

// ============================================================================
// DualStunShspHandler — IDualStunHandlerDelegationMixin getters / methods
// ============================================================================

Future<void> dualStunShspHandlerIpHandlersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('ipv4Handler: ${handler.ipv4Handler?.runtimeType}');
  print('ipv6Handler: ${handler.ipv6Handler?.runtimeType}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSetIpHandlerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final stun = handler.ipv4StunShspHandler.stunHandler;
  handler.clearIpv4Handler();
  handler.setIpv4Handler(stun);
  print('setIpv4Handler: handler re-injected');
  handler.destroy();
}

Future<void> dualStunShspHandlerClearHandlerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.clearIpv4Handler();
  print('clearIpv4Handler: ipv4Handler is null=${handler.ipv4Handler == null}');
  handler.destroy();
}

Future<void> dualStunShspHandlerReplaceHandlerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final stun = handler.ipv4StunShspHandler.stunHandler;
  handler.replaceHandler(stun, ipv6: false);
  print('replaceHandler: IPv4 handler replaced in-place');
  handler.destroy();
}

Future<void> dualStunShspHandlerPerformStunRequestExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final response = await handler.performStunRequest();
  print('performStunRequest ipv4: ${response.stunResponseIpv4?.publicIp}:${response.stunResponseIpv4?.publicPort}');
  print('performStunRequest ipv6: ${response.stunResponseIpv6?.publicIp}:${response.stunResponseIpv6?.publicPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerPerformLocalRequestExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final info = await handler.performLocalRequest();
  print('performLocalRequest ipv4: ${info.localDualInfoIpv4?.localIp}:${info.localDualInfoIpv4?.localPort}');
  print('performLocalRequest ipv6: ${info.localDualInfoIpv6?.localIp}:${info.localDualInfoIpv6?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerPingStunServerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ipv4Alive = await handler.pingStunServer(ipv6: false);
  final ipv6Alive = await handler.pingStunServer(ipv6: true);
  print('pingStunServer: ipv4=$ipv4Alive, ipv6=$ipv6Alive');
  handler.destroy();
}

Future<void> dualStunShspHandlerGetSocketExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ipv4Raw = handler.getSocket(ipv6: false);
  final ipv6Raw = handler.getSocket(ipv6: true);
  print('getSocket: ipv4 port=${ipv4Raw.port}, ipv6 port=${ipv6Raw.port}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSetStunServerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.setStunServer('stun.l.google.com', 19302);
  print('setStunServer: applied to both (ipv6 omitted)');
  handler.destroy();
}

Future<void> dualStunShspHandlerSetStunServerPerProtocolExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.setStunServer('stun.l.google.com', 19302, ipv6: false);
  handler.setStunServer('stun.l.google.com', 19302, ipv6: true);
  print('setStunServer: configured per protocol');
  handler.destroy();
}

Future<void> dualStunShspHandlerCloseExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.close(ipv6: false);
  print('close(ipv6:false): ipv4 closed=${handler.ipv4ShspSocket.isClosed}');
  handler.close(ipv6: true);
  print('close(ipv6:true): ipv6 closed=${handler.ipv6ShspSocket.isClosed}');
}

Future<void> dualStunShspHandlerLastStunTimestampsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.performStunRequest();
  print('ipv4LastStunUpdated: ${handler.ipv4LastStunUpdated}');
  print('ipv6LastStunUpdated: ${handler.ipv6LastStunUpdated}');
  handler.destroy();
}

Future<void> dualStunShspHandlerLastLocalTimestampsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.performLocalRequest();
  print('ipv4LastLocalUpdated: ${handler.ipv4LastLocalUpdated}');
  print('ipv6LastLocalUpdated: ${handler.ipv6LastLocalUpdated}');
  handler.destroy();
}

Future<void> dualStunShspHandlerLastStunUpdatedExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.performStunRequest();
  print('lastStunUpdated: ${handler.lastStunUpdated}');
  handler.destroy();
}

Future<void> dualStunShspHandlerLastLocalUpdatedExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.performLocalRequest();
  print('lastLocalUpdated: ${handler.lastLocalUpdated}');
  handler.destroy();
}

Future<void> dualStunShspHandlerInitializeDIExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.initializeDI();
  print('initializeDI: completed');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — DualShspSocketWrapperDelegationMixin properties
// ============================================================================

Future<void> dualStunShspHandlerRawSocketsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('ipv4Socket: port=${handler.ipv4Socket?.localPort}');
  print('ipv6Socket: port=${handler.ipv6Socket?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSocketWrappersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('ipv4SocketWrapper: port=${handler.ipv4SocketWrapper.localPort}');
  print('ipv6SocketWrapper: port=${handler.ipv6SocketWrapper.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSocketImplExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('ipv4SocketImpl: port=${handler.ipv4SocketImpl?.localPort}');
  print('ipv6SocketImpl: port=${handler.ipv6SocketImpl?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerExtractProfileExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final profile = handler.extractProfile();
  print('extractProfile: ${profile.runtimeType}');
  handler.destroy();
}

Future<void> dualStunShspHandlerApplyProfileExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final profile = handler.extractProfile();
  handler.applyProfile(profile);
  print('applyProfile: profile reapplied');
  handler.destroy();
}

Future<void> dualStunShspHandlerDualSocketStateExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('isClosed: ${handler.isClosed}');
  print('localAddress: ${handler.localAddress}');
  print('localPort: ${handler.localPort}');
  print('compressionCodec: ${handler.compressionCodec.runtimeType}');
  handler.destroy();
}

Future<void> dualStunShspHandlerRawSocketExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final raw = handler.socket;
  print('socket (RawDatagramSocket): port=${raw.port}, address=${raw.address}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSerializedObjectExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final serialized = handler.serializedObject();
  print('serializedObject: length=${serialized.length}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCallbacksExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.onClose.register((socket) => print('dual socket closed on ${socket.localPort}'));
  handler.onListening.register((socket) => print('dual socket listening on ${socket.localPort}'));
  print('onClose / onListening callbacks registered');
  handler.destroy();
}
