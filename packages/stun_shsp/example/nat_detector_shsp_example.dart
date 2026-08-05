// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

/// Constructor `NATDetectorShsp({socket, primaryServer, primaryPort, timeout})`
Future<void> natDetectorShspConstructorExample() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final detector = NATDetectorShsp(
    primaryServer: 'stun.l.google.com',
    primaryPort: 19302,
    socket: socket,
  );
  print('NATDetectorShsp created: ${detector.runtimeType}');
  socket.close();
}

/// Only the socket is required — the server and the timeout come from the
/// `nat` section of the `stun` configuration sector, which owns it.
Future<void> natDetectorShspFromConfigExample() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final detector = NATDetectorShsp(socket: socket);
  print('NATDetectorShsp from config: '
      '${detector.primaryServer}:${detector.primaryPort} '
      'timeout=${detector.timeout}');
  socket.close();
}

/// The detector can run straight on a combined handler's socket, so the NAT
/// probe and the SHSP traffic share the mapping the NAT sees.
Future<void> natDetectorShspOnHandlerSocketExample() async {
  final handler = await StunShspHandler.createDefault(ipv6: false);
  final detector = NATDetectorShsp(socket: handler);
  print('NATDetectorShsp bound to the handler socket on port '
      '${handler.localPort}: ${detector.runtimeType}');
  handler.close();
}

/// `natShspCompatibility()` — performs full NAT detection and adds SHSP compatibility check.
Future<void> natDetectorShspNatShspCompatibilityExample() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final detector = NATDetectorShsp(
    primaryServer: 'stun.l.google.com',
    primaryPort: 19302,
    socket: socket,
    timeout: const Duration(seconds: 10),
  );

  final result = await detector.natShspCompatibility();
  print('NAT Type           : ${result.natType.displayName}');
  print('Filtering Behavior : ${result.filteringBehavior.displayName}');
  print('Mapping Behavior   : ${result.mappingBehavior.displayName}');
  print('Public IP          : ${result.publicIp}:${result.publicPort}');
  print('SHSP Compatible    : ${result.isNatShspsCompatible}');
  print('Detection Time     : ${result.detectionTime}');

  socket.close();
}
