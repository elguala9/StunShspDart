import 'dart:io';

import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Every NAT type, paired with the SHSP verdict `natShspCompatibility()` must
/// report for it. Spelled out instead of derived from the implementation, so a
/// changed classification fails here instead of agreeing with itself.
const Map<NATType, bool> _expectedCompatibility = {
  NATType.openInternet: true,
  NATType.fullCone: true,
  NATType.restrictedCone: true,
  NATType.portRestrictedCone: true,
  NATType.symmetric: false,
  NATType.symmetricFirewall: false,
  NATType.udpBlocked: false,
};

/// A detector whose detection is canned, so the classification can be checked
/// for every NAT type without a STUN server — and without depending on the NAT
/// the test host happens to sit behind.
class _CannedDetector extends NATDetectorShsp {
  _CannedDetector({required super.socket, required this.canned});

  final NATDetectionResult canned;

  @override
  Future<NATDetectionResult> detectNATType() async => canned;
}

NATDetectionResult _resultFor(NATType type) => (
  natType: type,
  filteringBehavior: NATFilteringBehavior.addressDependent,
  mappingBehavior: NATMappingBehavior.endpointIndependent,
  publicIp: '203.0.113.7',
  publicPort: 41234,
  alternateIp: '203.0.113.8',
  alternatePort: 41235,
  rfc5780Supported: true,
  detectionTime: const Duration(milliseconds: 1234),
  diagnostics: const {'test1': 'ok'},
);

void main() {
  group('NATDetectorShsp — constructor', () {
    late RawDatagramSocket socket;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    });

    tearDown(() {
      socket.close();
    });

    test('keeps the server, port and timeout it was given', () {
      final detector = NATDetectorShsp(
        primaryServer: 'stun.example.org',
        primaryPort: 3478,
        socket: socket,
        timeout: const Duration(seconds: 10),
      );

      expect(detector.primaryServer, 'stun.example.org');
      expect(detector.primaryPort, 3478);
      expect(detector.timeout, const Duration(seconds: 10));
      expect(detector.socket, same(socket));
    });

    test('server, port and timeout default to the `stun` configuration', () {
      initStunConfig({
        'nat': {
          'primaryServer': 'stun.example.org',
          'primaryPort': 3478,
          'timeoutSeconds': 9.0,
        },
      });
      addTearDown(initStunShspConfig);

      final detector = NATDetectorShsp(socket: socket);

      expect(detector.primaryServer, 'stun.example.org');
      expect(detector.primaryPort, 3478);
      expect(detector.timeout, const Duration(seconds: 9));
    });

    test('an explicit argument wins over the configuration', () {
      initStunConfig({
        'nat': {'primaryServer': 'stun.example.org', 'primaryPort': 3478},
      });
      addTearDown(initStunShspConfig);

      final detector = NATDetectorShsp(
        primaryServer: 'stun.other.org',
        socket: socket,
      );

      expect(detector.primaryServer, 'stun.other.org');
      // Only what was passed is overridden.
      expect(detector.primaryPort, 3478);
    });
  });

  group('NATDetectorShsp — natShspCompatibility() classification', () {
    late RawDatagramSocket socket;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    });

    tearDown(() {
      socket.close();
    });

    test('every NAT type of the `stun` package is classified', () {
      // A NAT type added upstream must be given a verdict here on purpose,
      // instead of silently inheriting one.
      expect(_expectedCompatibility.keys.toSet(), NATType.values.toSet());
    });

    for (final entry in _expectedCompatibility.entries) {
      test('${entry.key.name} is SHSP-compatible: ${entry.value}', () async {
        final detector = _CannedDetector(
          socket: socket,
          canned: _resultFor(entry.key),
        );

        final result = await detector.natShspCompatibility();

        expect(result.isNatShspsCompatible, entry.value);
        expect(result.natType, entry.key);
      });
    }

    test('forwards every field of the detection result unchanged', () async {
      final canned = _resultFor(NATType.fullCone);
      final detector = _CannedDetector(socket: socket, canned: canned);

      final result = await detector.natShspCompatibility();

      expect(result.natType, canned.natType);
      expect(result.filteringBehavior, canned.filteringBehavior);
      expect(result.mappingBehavior, canned.mappingBehavior);
      expect(result.publicIp, canned.publicIp);
      expect(result.publicPort, canned.publicPort);
      expect(result.alternateIp, canned.alternateIp);
      expect(result.alternatePort, canned.alternatePort);
      expect(result.rfc5780Supported, canned.rfc5780Supported);
      expect(result.detectionTime, canned.detectionTime);
      expect(result.diagnostics, canned.diagnostics);
    });

    test('a null public endpoint stays null', () async {
      final canned = (
        natType: NATType.udpBlocked,
        filteringBehavior: NATFilteringBehavior.unknown,
        mappingBehavior: NATMappingBehavior.unknown,
        publicIp: null,
        publicPort: null,
        alternateIp: null,
        alternatePort: null,
        rfc5780Supported: false,
        detectionTime: Duration.zero,
        diagnostics: const <String, dynamic>{},
      );
      final detector = _CannedDetector(socket: socket, canned: canned);

      final result = await detector.natShspCompatibility();

      expect(result.publicIp, isNull);
      expect(result.publicPort, isNull);
      expect(result.isNatShspsCompatible, isFalse);
    });
  });

  group('NATDetectorShsp — against a real STUN server', () {
    late RawDatagramSocket socket;

    setUp(() async {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    });

    tearDown(() {
      socket.close();
    });

    // Needs the network; whatever NAT the host sits behind, the verdict must
    // agree with the table above — an unconditional assertion, so this cannot
    // pass by never reaching a branch.
    test('the verdict matches the detected type', () async {
      final detector = NATDetectorShsp(
        socket: socket,
        timeout: const Duration(seconds: 10),
      );

      final result = await detector.natShspCompatibility();

      expect(_expectedCompatibility.containsKey(result.natType), isTrue);
      expect(
        result.isNatShspsCompatible,
        _expectedCompatibility[result.natType],
        reason: 'detected ${result.natType.name}',
      );
      if (result.natType != NATType.udpBlocked) {
        expect(result.publicIp, isNotNull);
        expect(result.publicPort, greaterThan(0));
      }
      expect(result.detectionTime, greaterThan(Duration.zero));
    });
  });
}
