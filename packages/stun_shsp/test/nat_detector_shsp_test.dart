import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

void main() {
  group('NATDetectorShsp — constructor', () {
    late RawDatagramSocket socket;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    });

    tearDown(() {
      socket.close();
      SingletonManager.instance.destroyAll();
    });

    test('creates a NATDetectorShsp with required parameters', () {
      final detector = NATDetectorShsp(
        primaryServer: 'stun.l.google.com',
        primaryPort: 19302,
        socket: socket,
      );
      expect(detector, isA<NATDetectorShsp>());
      expect(detector, isA<NATDetector>());
    });

    test('creates with custom timeout', () {
      final detector = NATDetectorShsp(
        primaryServer: 'stun.l.google.com',
        primaryPort: 19302,
        socket: socket,
        timeout: const Duration(seconds: 10),
      );
      expect(detector, isA<NATDetectorShsp>());
    });
  });

  group('NATDetectorShsp — natShspCompatibility()', () {
    late RawDatagramSocket socket;
    late NATDetectorShsp detector;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      detector = NATDetectorShsp(
        primaryServer: 'stun.l.google.com',
        primaryPort: 19302,
        socket: socket,
        timeout: const Duration(seconds: 10),
      );
    });

    tearDown(() {
      socket.close();
      SingletonManager.instance.destroyAll();
    });

    test('returns a NatShspCompatibilityResult', () async {
      final result = await detector.natShspCompatibility();
      expect(result.natType, isA<NATType>());
      expect(result.filteringBehavior, isA<NATFilteringBehavior>());
      expect(result.mappingBehavior, isA<NATMappingBehavior>());
      expect(result.rfc5780Supported, isA<bool>());
      expect(result.detectionTime, isA<Duration>());
      expect(result.diagnostics, isA<Map<String, dynamic>>());
      expect(result.isNatShspsCompatible, isA<bool>());
    });

    test('isNatShspsCompatible field is present in result', () async {
      final result = await detector.natShspCompatibility();
      expect(result.isNatShspsCompatible, anyOf(isTrue, isFalse));
    });

    test('publicIp is a String when available', () async {
      final result = await detector.natShspCompatibility();
      if (result.natType != NATType.udpBlocked) {
        expect(result.publicIp, isNotNull);
        expect(result.publicPort, isNotNull);
      }
    });

    test('SHSP-compatible NAT types return isNatShspsCompatible true', () async {
      final result = await detector.natShspCompatibility();
      final compatibleTypes = {
        NATType.openInternet,
        NATType.fullCone,
        NATType.restrictedCone,
        NATType.portRestrictedCone,
      };

      if (compatibleTypes.contains(result.natType)) {
        expect(result.isNatShspsCompatible, isTrue);
      }
    });

    test('SHSP-incompatible NAT types return isNatShspsCompatible false', () async {
      final result = await detector.natShspCompatibility();
      final incompatibleTypes = {
        NATType.symmetric,
        NATType.symmetricFirewall,
        NATType.udpBlocked,
      };

      if (incompatibleTypes.contains(result.natType)) {
        expect(result.isNatShspsCompatible, isFalse);
      }
    });
  });
}
