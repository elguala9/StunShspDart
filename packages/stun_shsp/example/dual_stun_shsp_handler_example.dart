// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// DualStunShspHandler — constructors
// ============================================================================

Future<void> dualStunShspHandlerConstructorExample() async {
  final ipv4Socket = await ShspSocket.bindDefault(ipv6: false);
  final ipv6Socket = await ShspSocket.bindIfPossible(
    InternetAddress.anyIPv6,
    0,
  );
  final handler = DualStunShspHandler.fromSockets(
    Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket),
  );
  print('DualStunShspHandler created from sockets, '
      'ipv4=${handler.getSocket(InternetAddressType.IPv4)?.localPort} '
      'ipv6=${handler.getSocket(InternetAddressType.IPv6)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerFromMigratableExample() async {
  final ipv4 = ShspSocketMigratable(await ShspSocket.bindDefault(ipv6: false));
  final handler = DualStunShspHandler(ipv4Migratable: ipv4);
  print('DualStunShspHandler created from an IPv4 migratable socket only, '
      'ipv6StunShspHandler=${handler.ipv6StunShspHandler}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('createDefault() bound '
      'ipv4=${handler.getSocket(InternetAddressType.IPv4)?.localPort} '
      'ipv6=${handler.getSocket(InternetAddressType.IPv6)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultPortsExample() async {
  final handler = await DualStunShspHandler.createDefault(
    ipv4Port: 0,
    ipv6Port: 0,
  );
  print('createDefault(ports) bound '
      'ipv4=${handler.getSocket(InternetAddressType.IPv4)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCreateDefaultCodecExample() async {
  final handler = await DualStunShspHandler.createDefault(
    compressionCodec: GZipCodec(),
  );
  print('createDefault with GZipCodec, '
      'codec=${handler.compressionCodec.runtimeType}');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — own getters
// ============================================================================

Future<void> dualStunShspHandlerStunShspGettersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('ipv4StunShspHandler=${handler.ipv4StunShspHandler?.localPort} '
      'ipv6StunShspHandler=${handler.ipv6StunShspHandler?.localPort} '
      'getStunShspHandler(IPv4)='
      '${handler.getStunShspHandler(InternetAddressType.IPv4)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSocketGettersExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('getSocket(IPv4)='
      '${handler.getSocket(InternetAddressType.IPv4)?.localPort} '
      'getSocketMigratable(IPv4)='
      '${handler.getSocketMigratable(InternetAddressType.IPv4).localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerDualStunHandlerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final stun = handler.dualStunHandler;
  print('dualStunHandler=${stun.runtimeType}, '
      'ipv4Handler is the combined handler='
      '${identical(stun.ipv4Handler, handler.ipv4StunShspHandler)}');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — own methods
// ============================================================================

Future<void> dualStunShspHandlerRefreshSocketExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final before = handler.getSocket(InternetAddressType.IPv4)?.localPort;
  handler.refreshSocket(InternetAddressType.IPv4);
  // The rebind is asynchronous; the migration that follows it rebuilds the
  // combined handler for that family on its own.
  await Future<void>.delayed(const Duration(milliseconds: 200));
  print('refreshSocket(IPv4): $before -> '
      '${handler.getSocket(InternetAddressType.IPv4)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerRefreshSocketsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final sockets = handler.refreshSockets();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  print('refreshSockets() -> ipv4=${sockets.ipv4SocketImpl?.localPort} '
      'ipv6=${sockets.ipv6SocketImpl?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerMigrateSocketIpv4Example() async {
  final handler = await DualStunShspHandler.createDefault();
  final newSocket = await ShspSocket.bindDefault(ipv6: false);
  handler.migrateSocketIpv4(newSocket);
  print('migrateSocketIpv4 -> socket='
      '${handler.getSocket(InternetAddressType.IPv4)?.localPort} '
      'stun=${handler.dualStunHandler.ipv4Handler?.getSocket().port}');
  handler.destroy();
}

Future<void> dualStunShspHandlerMigrateSocketExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final newSocket = await ShspSocket.bindDefault(ipv6: false);
  handler.migrateSocket(newSocket, InternetAddressType.IPv4);
  print('migrateSocket(IPv4) -> '
      '${handler.getSocket(InternetAddressType.IPv4)?.localPort}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCloseExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.close(type: InternetAddressType.IPv4);
  print('close(type: IPv4) -> '
      'ipv4Closed=${handler.getSocket(InternetAddressType.IPv4)?.isClosed} '
      'allClosed=${handler.isClosed}');
  handler.close();
  print('close() -> allClosed=${handler.isClosed}');
}

Future<void> dualStunShspHandlerDestroyExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.destroy();
  print('destroy() -> isClosed=${handler.isClosed}');
}

// ============================================================================
// DualStunShspHandler — DualStunHandlerDelegationMixin (the STUN half)
// ============================================================================

Future<void> dualStunShspHandlerPerformStunRequestExample() async {
  final handler = await DualStunShspHandler.createDefault();
  try {
    final response = await handler.performStunRequest();
    print('performStunRequest -> '
        'v4=${response.publicIp(InternetAddressType.IPv4)} '
        'v6=${response.publicIp(InternetAddressType.IPv6)}');
  } catch (e) {
    print('performStunRequest failed (no network?): $e');
  }
  handler.destroy();
}

Future<void> dualStunShspHandlerPerformLocalRequestExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final local = await handler.performLocalRequest();
  print('performLocalRequest -> v4=${local.localIpv4}:${local.localPortIpv4} '
      'v6=${local.localIpv6}:${local.localPortIpv6}');
  handler.destroy();
}

Future<void> dualStunShspHandlerPingStunServerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('pingStunServer -> ${await handler.pingStunServer()}');
  handler.destroy();
}

Future<void> dualStunShspHandlerSetStunServerExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.setStunServer('stun.cloudflare.com', 3478);
  handler.setStunServer(
    'stun.l.google.com',
    19302,
    type: InternetAddressType.IPv4,
  );
  print('setStunServer applied to both families, then to IPv4 only');
  handler.destroy();
}

Future<void> dualStunShspHandlerHandlerSlotsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final ipv4 = handler.getHandler(type: InternetAddressType.IPv4);
  print('getHandler(IPv4)=${ipv4?.runtimeType}');

  handler.clearHandler(type: InternetAddressType.IPv4);
  print('after clearHandler -> ${handler.ipv4Handler}');

  if (ipv4 != null) {
    handler.setHandler(ipv4, type: InternetAddressType.IPv4);
    print('after setHandler -> ${handler.ipv4Handler?.runtimeType}');
    handler.replaceHandler(ipv4, type: InternetAddressType.IPv4);
    print('after replaceHandler -> ${handler.ipv4Handler?.runtimeType}');
  }
  handler.destroy();
}

Future<void> dualStunShspHandlerTimestampsExample() async {
  final handler = await DualStunShspHandler.createDefault();
  await handler.performLocalRequest();
  print('lastLocalUpdated=${handler.lastLocalUpdated} '
      'ipv4=${handler.getLastLocalUpdated(type: InternetAddressType.IPv4)} '
      'lastStunUpdated=${handler.lastStunUpdated}');
  handler.destroy();
}

// ============================================================================
// DualStunShspHandler — the dual SHSP socket it is
// ============================================================================

Future<void> dualStunShspHandlerSendToExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final peer = PeerInfo(
    address: InternetAddress.loopbackIPv4,
    port: handler.getSocket(InternetAddressType.IPv4)!.localPort!,
  );
  print('sendTo -> ${handler.sendTo([1, 2, 3], peer)} byte(s) '
      'routed to the IPv4 socket');
  handler.destroy();
}

Future<void> dualStunShspHandlerProfileExample() async {
  final handler = await DualStunShspHandler.createDefault();
  final profile = handler.extractProfile();
  handler.applyProfile(profile);
  print('extractProfile/applyProfile round-trip done');
  handler.destroy();
}

Future<void> dualStunShspHandlerSerializedObjectExample() async {
  final handler = await DualStunShspHandler.createDefault();
  print('serializedObject=${handler.serializedObject()}');
  handler.destroy();
}

Future<void> dualStunShspHandlerCallbacksExample() async {
  final handler = await DualStunShspHandler.createDefault();
  handler.onClose.register(
    (socket) => print('socket closed: ${socket.localPort}'),
  );
  handler.onError.register((e) => print('socket error: ${e.error}'));
  print('close/error callbacks registered');
  handler.destroy();
}
