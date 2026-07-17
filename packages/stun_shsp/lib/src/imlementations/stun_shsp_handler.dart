import 'dart:async';

import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';

import 'package:stun_shsp/src/interfaces/i_stun_shsp_handler.dart';
import 'package:stun_shsp/src/mixins/i_stun_handler_delegation_mixin.dart';

class StunShspHandler
    with ShspSocketWrapperDelegationMixin, IStunHandlerDelegationMixin
    implements IValueForRegistry, IStunShspHandler {
  StunShspHandler(this._shspSocket)
      : _stunHandler = StunHandler.withSocket(_shspSocket);

  static Future<StunShspHandler> createDefault({
    bool ipv6 = true,
    int port = 0,
    ICompressionCodec? compressionCodec,
  }) async {
    final shspSocketWrapper = ShspSocketWrapper(
      await ShspSocket.bindDefault(
        ipv6: ipv6,
        port: port,
        compressionCodec: compressionCodec,
      ),
    );
    return StunShspHandler(shspSocketWrapper);
  }

  final IStunHandler _stunHandler;
  final IShspSocketWrapper _shspSocket;

  @override
  IShspSocket get delegateSocket => _shspSocket;

  @override
  IStunHandler get delegateStunHandler => _stunHandler;

  @override
  void migrateSocket(IShspSocket socket) => _shspSocket.migrateSocket(socket);

  @override
  void close() {
    _stunHandler.close();
    _shspSocket.close();
  }

  @override
  void destroy() {
    _stunHandler.destroy();
    _shspSocket.destroy();
  }

  @override
  IStunHandler get stunHandler => _stunHandler;

  @override
  IShspSocketWrapper get shspSocket => _shspSocket;
}
