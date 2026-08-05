import 'dart:io';

import 'package:stun/stun.dart';

/// Forwards the whole [IStunHandler] surface to [delegateStunHandler].
///
/// Mixed in next to `ShspSocketMigratableDelegationMixin`, it turns a class
/// that already is an SHSP socket into an [IStunHandler] as well. Both mixins
/// declare `close()`: the mixing class has to override it and decide what
/// closing means for the pair.
mixin StunHandlerDelegationMixin implements IStunHandler {
  /// STUN handler provided by the mixing class.
  IStunHandler get delegateStunHandler;

  @override
  Future<StunResponse> performStunRequest() =>
      delegateStunHandler.performStunRequest();

  @override
  Future<LocalInfo> performLocalRequest() =>
      delegateStunHandler.performLocalRequest();

  @override
  Future<bool> pingStunServer() => delegateStunHandler.pingStunServer();

  @override
  void setStunServer(String address, int port) =>
      delegateStunHandler.setStunServer(address, port);

  @override
  RawDatagramSocket getSocket() => delegateStunHandler.getSocket();

  @override
  InternetAddressType getIpVersion() => delegateStunHandler.getIpVersion();

  @override
  void close() => delegateStunHandler.close();

  @override
  DateTime? get lastStunUpdated => delegateStunHandler.lastStunUpdated;

  @override
  DateTime? get lastLocalUpdated => delegateStunHandler.lastLocalUpdated;
}
