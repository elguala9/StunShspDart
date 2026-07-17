// ignore_for_file: avoid_print
import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';

/// Constructor `NATDetectorShsp({primaryServer, primaryPort, socket, timeout})`
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
