import 'package:stun/stun.dart';

import 'package:stun_shsp/src/config/stun_shsp_config.dart';

typedef NatShspCompatibilityResult = ({
  NATType natType,
  NATFilteringBehavior filteringBehavior,
  NATMappingBehavior mappingBehavior,
  String? publicIp,
  int? publicPort,
  String? alternateIp,
  int? alternatePort,
  bool rfc5780Supported,
  Duration detectionTime,
  Map<String, dynamic> diagnostics,
  bool isNatShspsCompatible,
});

class NATDetectorShsp extends NATDetector {
  /// [primaryServer], [primaryPort] and [timeout] fall back to the
  /// `nat` section of the `stun_shsp` configuration sector; see
  /// [StunShspConfigExtension].
  NATDetectorShsp({
    required super.socket,
    String? primaryServer,
    int? primaryPort,
    Duration? timeout,
  }) : super(
          primaryServer: primaryServer ?? defaultStunShspNatPrimaryServer(),
          primaryPort: primaryPort ?? defaultStunShspNatPrimaryPort(),
          timeout: timeout ?? defaultStunShspNatTimeout(),
        );

  Future<NatShspCompatibilityResult> natShspCompatibility() async {
    final result = await detectNATType();
    final compatible = _isNatShspCompatible(result.natType);
    return (
      natType: result.natType,
      filteringBehavior: result.filteringBehavior,
      mappingBehavior: result.mappingBehavior,
      publicIp: result.publicIp,
      publicPort: result.publicPort,
      alternateIp: result.alternateIp,
      alternatePort: result.alternatePort,
      rfc5780Supported: result.rfc5780Supported,
      detectionTime: result.detectionTime,
      diagnostics: result.diagnostics,
      isNatShspsCompatible: compatible,
    );
  }

  static bool _isNatShspCompatible(NATType natType) {
    switch (natType) {
      case NATType.symmetric:
      case NATType.symmetricFirewall:
      case NATType.udpBlocked:
        return false;
      case NATType.openInternet:
      case NATType.fullCone:
      case NATType.restrictedCone:
      case NATType.portRestrictedCone:
        return true;
    }
  }
}
