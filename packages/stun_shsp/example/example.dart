// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

/// Example: DI-based initialization (recommended for apps)
Future<void> diExample() async {
  // Bootstrap SHSP sockets, STUN handlers and DI wiring in one call.
  await initializePointStunShsp();

  final handler = SingletonDIAccess.get<IStunShspHandler>();

  // Discover the public IP and port via STUN.
  final stun = await handler.performStunRequest();
  print('Public address : ${stun.publicIp}:${stun.publicPort}');
  print('IP version     : ${stun.ipVersion}');

  // Retrieve local address information.
  final local = await handler.performLocalRequest();
  print('Local address  : ${local.localIp}:${local.localPort}');

  // The dual socket routes packets automatically between IPv4 and IPv6.
  final dual = handler.dualShspSocket;
  print('IPv4 local port: ${dual.ipv4Socket.localPort}');
  if (dual.ipv6Socket != null) {
    print('IPv6 local port: ${dual.ipv6Socket!.localPort}');
  }

  handler.close();
  SingletonManager.instance.destroyAll();
}

/// Example: manual instantiation (no DI)
Future<void> manualExample() async {
  final handler = StunShspHandlerSingleton();

  await handler.initialize(
    address: '0.0.0.0',
    port: 0, // 0 = OS-assigned ephemeral port
    timeout: const Duration(seconds: 5),
    // compressionCodec: MyCodec(), // optional
  );

  final stun = await handler.performStunRequest();
  print('Public address: ${stun.publicIp}:${stun.publicPort}');

  // Migrate to a new socket at runtime (e.g. after a network change).
  final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
  handler.migrateSocketIpv4(newSocket);
  print('Migrated IPv4 port: ${handler.ipv4ShspSocket.localPort}');

  handler.close();
}

Future<void> main() async {
  print('=== DI example ===');
  await diExample();

  print('\n=== Manual example ===');
  await manualExample();
}
