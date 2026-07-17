import 'dart:io';

import 'package:stun/stun.dart';

mixin IDualStunHandlerDelegationMixin implements IDualStunHandler {
  IDualStunHandler get delegateDualStunHandler;

  @override
  IStunHandler? get ipv4Handler => delegateDualStunHandler.ipv4Handler;

  @override
  IStunHandler? get ipv6Handler => delegateDualStunHandler.ipv6Handler;

  @override
  void setIpv4Handler(IStunHandler handler) =>
      delegateDualStunHandler.setIpv4Handler(handler);

  @override
  void setIpv6Handler(IStunHandler handler) =>
      delegateDualStunHandler.setIpv6Handler(handler);

  @override
  void clearIpv4Handler() => delegateDualStunHandler.clearIpv4Handler();

  @override
  void clearIpv6Handler() => delegateDualStunHandler.clearIpv6Handler();

  @override
  void replaceHandler(IStunHandler handler, {required bool ipv6}) =>
      delegateDualStunHandler.replaceHandler(handler, ipv6: ipv6);

  @override
  Future<StunDualResponse> performStunRequest() =>
      delegateDualStunHandler.performStunRequest();

  @override
  Future<LocalDualInfo> performLocalRequest() =>
      delegateDualStunHandler.performLocalRequest();

  @override
  Future<bool> pingStunServer({bool ipv6 = true}) =>
      delegateDualStunHandler.pingStunServer(ipv6: ipv6);

  @override
  RawDatagramSocket getSocket({bool ipv6 = true}) =>
      delegateDualStunHandler.getSocket(ipv6: ipv6);

  @override
  void setStunServer(String address, int port, {bool? ipv6}) =>
      delegateDualStunHandler.setStunServer(address, port, ipv6: ipv6);

  @override
  void close({bool? ipv6}) => delegateDualStunHandler.close(ipv6: ipv6);

  @override
  DateTime? get ipv4LastStunUpdated =>
      delegateDualStunHandler.ipv4LastStunUpdated;

  @override
  DateTime? get ipv6LastStunUpdated =>
      delegateDualStunHandler.ipv6LastStunUpdated;

  @override
  DateTime? get ipv4LastLocalUpdated =>
      delegateDualStunHandler.ipv4LastLocalUpdated;

  @override
  DateTime? get ipv6LastLocalUpdated =>
      delegateDualStunHandler.ipv6LastLocalUpdated;

  @override
  DateTime? get lastStunUpdated => delegateDualStunHandler.lastStunUpdated;

  @override
  DateTime? get lastLocalUpdated => delegateDualStunHandler.lastLocalUpdated;

  @override
  Future<void> initializeDI() => delegateDualStunHandler.initializeDI();
}
