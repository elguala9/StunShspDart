import 'dart:io';

import 'package:stun/stun.dart';

/// Forwards the STUN half of a dual-stack handler to
/// [delegateDualStunHandler].
///
/// Deliberately *not* `implements IDualStunHandler`: [IDualStunHandler]
/// declares `RawDatagramSocket getSocket({InternetAddressType type})` while
/// `IDualShspSocket` declares `IShspSocket? getSocket([InternetAddressType
/// type])`, and no single member satisfies both (named vs positional
/// parameter, and a nullable `IShspSocket` is not a `RawDatagramSocket`). A
/// class that already is a dual SHSP socket can therefore expose everything
/// else of the STUN surface, but not that one method — the STUN sockets stay
/// reachable through `delegateDualStunHandler.getSocket(type: ...)`.
mixin DualStunHandlerDelegationMixin {
  /// Dual STUN handler provided by the mixing class.
  IDualStunHandler get delegateDualStunHandler;

  Future<StunResponse> performStunRequest() =>
      delegateDualStunHandler.performStunRequest();

  Future<LocalInfo> performLocalRequest() =>
      delegateDualStunHandler.performLocalRequest();

  Future<bool> pingStunServer() => delegateDualStunHandler.pingStunServer();

  void setStunServer(String address, int port, {InternetAddressType? type}) =>
      delegateDualStunHandler.setStunServer(address, port, type: type);

  IStunHandler? getHandler({
    InternetAddressType type = InternetAddressType.IPv6,
  }) => delegateDualStunHandler.getHandler(type: type);

  void setHandler(
    IStunHandler handler, {
    InternetAddressType type = InternetAddressType.IPv6,
  }) => delegateDualStunHandler.setHandler(handler, type: type);

  void clearHandler({InternetAddressType type = InternetAddressType.IPv6}) =>
      delegateDualStunHandler.clearHandler(type: type);

  void replaceHandler(
    IStunHandler handler, {
    InternetAddressType type = InternetAddressType.IPv6,
  }) => delegateDualStunHandler.replaceHandler(handler, type: type);

  IStunHandler? get ipv4Handler => delegateDualStunHandler.ipv4Handler;

  IStunHandler? get ipv6Handler => delegateDualStunHandler.ipv6Handler;

  DateTime? getLastStunUpdated({
    InternetAddressType type = InternetAddressType.IPv6,
  }) => delegateDualStunHandler.getLastStunUpdated(type: type);

  DateTime? getLastLocalUpdated({
    InternetAddressType type = InternetAddressType.IPv6,
  }) => delegateDualStunHandler.getLastLocalUpdated(type: type);

  DateTime? get lastStunUpdated => delegateDualStunHandler.lastStunUpdated;

  DateTime? get lastLocalUpdated => delegateDualStunHandler.lastLocalUpdated;
}
