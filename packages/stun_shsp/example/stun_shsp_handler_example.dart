// ignore_for_file: avoid_print
import 'package:stun_shsp/stun_shsp.dart';

// ============================================================================
// StunShspHandler — constructors
// ============================================================================

Future<void> stunShspHandlerConstructorExample() async {
  final socket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  final handler = StunShspHandler(ShspSocketMigratable(socket));
  print('StunShspHandler created via constructor, '
      'port=${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerConstructorWithStunServerExample() async {
  final socket = await ShspSocket.bindDefault(ipv6: false, port: 0);
  final handler = StunShspHandler(
    ShspSocketMigratable(socket),
    address: 'stun.cloudflare.com',
    port: 3478,
    timeout: const Duration(seconds: 3),
  );
  print('StunShspHandler created against an explicit STUN server, '
      'port=${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultIpv4Example() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('createDefault(ipv6:false) bound to port '
      '${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultIpv6Example() async {
  final handler = await StunShspHandler.createDefault(ipv6: true);
  print('createDefault(ipv6:true) bound to port '
      '${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCreateDefaultPortExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false, port: 3478);
  print('createDefault(port:3478) bound to port '
      '${handler.shspSocket.localPort}');
  handler.close();
}

/// Everything left unset comes from the configuration: the port from the
/// `stun_shsp` sector, the address family from the `stun` one.
Future<void> stunShspHandlerCreateDefaultFromConfigExample() async {
  initStunShspConfig({
    'socket': {'ipv6': false, 'port': 0},
  });
  final handler = await StunShspHandler.createDefault();
  print('createDefault() from config: ipVersion=${handler.getIpVersion()}, '
      'port=${handler.shspSocket.localPort}');
  handler.close();
  initStunShspConfig();
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
  print('stunHandler is ${handler.stunHandler.runtimeType}');
  handler.close();
}

Future<void> stunShspHandlerShspSocketGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('shspSocket localPort=${handler.shspSocket.localPort}');
  handler.close();
}

Future<void> stunShspHandlerDelegateSocketGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final ds = handler.delegateSocket;
  print('delegateSocket localPort=${ds.localPort}, '
      'same as shspSocket=${identical(ds, handler.shspSocket)}');
  handler.close();
}

Future<void> stunShspHandlerDelegateStunHandlerGetterExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final dsh = handler.delegateStunHandler;
  print('delegateStunHandler is ${dsh.runtimeType}, '
      'same as stunHandler=${identical(dsh, handler.stunHandler)}');
  handler.close();
}

// ============================================================================
// StunShspHandler — own methods
// ============================================================================

/// Migrating swaps the socket under both halves at once: the STUN handler was
/// built on the migratable socket, not on the socket behind it.
Future<void> stunShspHandlerMigrateSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('before migrate: shsp=${handler.localPort} '
      'stun=${handler.getSocket().port}');

  final newSocket = await ShspSocket.bindDefault(ipv6: false);
  handler.migrateSocket(newSocket);

  print('after migrate:  shsp=${handler.localPort} '
      'stun=${handler.getSocket().port}');
  handler.close();
}

Future<void> stunShspHandlerCloseExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.close();
  print('close() -> isClosed=${handler.isClosed}');
}

Future<void> stunShspHandlerDestroyExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.destroy();
  print('destroy() -> isClosed=${handler.isClosed}');
}

// ============================================================================
// StunShspHandler — StunHandlerDelegationMixin (the STUN half)
// ============================================================================

Future<void> stunShspHandlerPerformStunRequestExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  try {
    final response = await handler.performStunRequest();
    final type = handler.getIpVersion();
    print('performStunRequest -> '
        '${response.publicIp(type)}:${response.publicPort(type)}');
  } catch (e) {
    print('performStunRequest failed (no network?): $e');
  }
  handler.close();
}

Future<void> stunShspHandlerPerformLocalRequestExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final local = await handler.performLocalRequest();
  print('performLocalRequest -> '
      '${local.localIpv4}:${local.localPortIpv4}');
  handler.close();
}

Future<void> stunShspHandlerPingStunServerExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('pingStunServer -> ${await handler.pingStunServer()}');
  handler.close();
}

Future<void> stunShspHandlerSetStunServerExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  handler.setStunServer('stun.cloudflare.com', 3478);
  print('setStunServer applied; ping -> ${await handler.pingStunServer()}');
  handler.close();
}

Future<void> stunShspHandlerGetSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('getSocket() -> port=${handler.getSocket().port}, '
      'getIpVersion() -> ${handler.getIpVersion()}');
  handler.close();
}

Future<void> stunShspHandlerLastStunUpdatedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('lastStunUpdated before any request -> ${handler.lastStunUpdated}');
  handler.close();
}

Future<void> stunShspHandlerLastLocalUpdatedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  await handler.performLocalRequest();
  print('lastLocalUpdated after a local request -> ${handler.lastLocalUpdated}');
  handler.close();
}

// ============================================================================
// StunShspHandler — ShspSocketMigratableDelegationMixin (the SHSP half)
// ============================================================================

Future<void> stunShspHandlerPortExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('port=${handler.port}');
  handler.close();
}

Future<void> stunShspHandlerAddressExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('address=${handler.address}');
  handler.close();
}

Future<void> stunShspHandlerSocketFlagsExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('broadcastEnabled=${handler.broadcastEnabled} '
      'readEventsEnabled=${handler.readEventsEnabled} '
      'writeEventsEnabled=${handler.writeEventsEnabled}');
  handler.close();
}

Future<void> stunShspHandlerLocalAddressExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('localAddress=${handler.localAddress} localPort=${handler.localPort}');
  handler.close();
}

Future<void> stunShspHandlerCompressionCodecExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('compressionCodec=${handler.compressionCodec.runtimeType}');
  handler.close();
}

Future<void> stunShspHandlerIsClosedExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('isClosed=${handler.isClosed}');
  handler.close();
  print('isClosed after close=${handler.isClosed}');
}

Future<void> stunShspHandlerProfileExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final profile = handler.extractProfile();
  handler.applyProfile(profile);
  print('extractProfile/applyProfile round-trip done');
  handler.close();
}

Future<void> stunShspHandlerRawSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('raw socket=${handler.socket.runtimeType} port=${handler.socket.port}');
  handler.close();
}

Future<void> stunShspHandlerSerializedObjectExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  print('serializedObject=${handler.serializedObject()}');
  handler.close();
}
