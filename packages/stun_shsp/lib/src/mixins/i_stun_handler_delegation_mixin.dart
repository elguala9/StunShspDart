import 'dart:io';

import 'package:stun/stun.dart';

mixin IStunHandlerDelegationMixin implements IStunHandler {
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
  void close() => delegateStunHandler.close();

  @override
  DateTime? get lastStunUpdated => delegateStunHandler.lastStunUpdated;

  @override
  DateTime? get lastLocalUpdated => delegateStunHandler.lastLocalUpdated;

  @override
  void addOnSocketRefresh(OnSocketRefresh callback) =>
      delegateStunHandler.addOnSocketRefresh(callback);

  @override
  void removeOnSocketRefresh(OnSocketRefresh callback) =>
      delegateStunHandler.removeOnSocketRefresh(callback);
}
