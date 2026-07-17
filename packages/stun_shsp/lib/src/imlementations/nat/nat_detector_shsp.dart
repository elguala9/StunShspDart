import 'package:stun/stun.dart';

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
  NATDetectorShsp({
    required super.primaryServer,
    required super.primaryPort,
    required super.socket,
    super.timeout,
  });

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
