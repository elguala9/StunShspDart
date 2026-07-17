import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';

import 'package:stun_shsp/src/imlementations/stun_shsp_handler.dart';
import 'package:stun_shsp/src/interfaces/i_dual_stun_shsp_handler.dart';
import 'package:stun_shsp/src/mixins/i_dual_stun_handler_delegation_mixin.dart';

class DualStunShspHandler
    with DualShspSocketWrapperDelegationMixin, IDualStunHandlerDelegationMixin
    implements IValueForRegistry, IDualStunShspHandler {
  DualStunShspHandler(IShspSocket ipv4Socket, IShspSocket ipv6Socket)
      : this._(_asWrapper(ipv4Socket), _asWrapper(ipv6Socket));

  DualStunShspHandler._(IShspSocketWrapper ipv4Wrapper, IShspSocketWrapper ipv6Wrapper)
      : _ipv4StunShspHandler = StunShspHandler(ipv4Wrapper),
        _ipv6StunShspHandler = StunShspHandler(ipv6Wrapper),
        _dualStunHandler = DualStunHandler(),
        _dualShspSocket = DualShspSocketAuto.fromWrappers(
          ipv4Wrapper: ipv4Wrapper,
          ipv6Wrapper: ipv6Wrapper,
        ) {
    _dualStunHandler.setIpv4Handler(_ipv4StunShspHandler.stunHandler);
    _dualStunHandler.setIpv6Handler(_ipv6StunShspHandler.stunHandler);
  }

  static IShspSocketWrapper _asWrapper(IShspSocket socket) =>
      socket is IShspSocketWrapper ? socket : ShspSocketWrapper(socket);

  static Future<DualStunShspHandler> createDefault({
    int ipv4Port = 0,
    int ipv6Port = 0,
    ICompressionCodec? compressionCodec,
  }) async {
    final ipv4Socket = await ShspSocket.bindDefault(
      ipv6: false,
      port: ipv4Port,
      compressionCodec: compressionCodec,
    );
    final ipv6Socket = await ShspSocket.bindDefault(
      ipv6: true,
      port: ipv6Port,
      compressionCodec: compressionCodec,
    );
    return DualStunShspHandler(ipv4Socket, ipv6Socket);
  }

  StunShspHandler _ipv4StunShspHandler;
  StunShspHandler _ipv6StunShspHandler;
  final DualStunHandler _dualStunHandler;
  final DualShspSocketAuto _dualShspSocket;

  @override
  IDualShspSocketAuto get delegateDualSocket => _dualShspSocket;

  @override
  IDualStunHandler get delegateDualStunHandler => _dualStunHandler;

  @override
  IShspSocket refreshSocketIpv4() {
    final socket = _dualShspSocket.refreshSocketIpv4();
    _rebuildIpv4StunHandler();
    return socket;
  }

  @override
  IShspSocket refreshSocketIpv6() {
    final socket = _dualShspSocket.refreshSocketIpv6();
    _rebuildIpv6StunHandler();
    return socket;
  }

  @override
  Sockets refreshSockets() {
    final sockets = _dualShspSocket.refreshSockets();
    _rebuildIpv4StunHandler();
    _rebuildIpv6StunHandler();
    return sockets;
  }

  @override
  void migrateSocketIpv4(IShspSocket socket) {
    _dualShspSocket.migrateSocketIpv4(socket);
    _rebuildIpv4StunHandler();
  }

  @override
  void migrateSocketIpv6(IShspSocket socket) {
    _dualShspSocket.migrateSocketIpv6(socket);
    _rebuildIpv6StunHandler();
  }

  void _rebuildIpv4StunHandler() {
    _ipv4StunShspHandler = StunShspHandler(_ipv4StunShspHandler.shspSocket);
    _dualStunHandler.replaceHandler(_ipv4StunShspHandler.stunHandler, ipv6: false);
  }

  void _rebuildIpv6StunHandler() {
    _ipv6StunShspHandler = StunShspHandler(_ipv6StunShspHandler.shspSocket);
    _dualStunHandler.replaceHandler(_ipv6StunShspHandler.stunHandler, ipv6: true);
  }

  @override
  void destroy() {
    _dualStunHandler.destroy();
    _dualShspSocket.destroy();
  }

  @override
  StunShspHandler get ipv4StunShspHandler => _ipv4StunShspHandler;

  @override
  StunShspHandler get ipv6StunShspHandler => _ipv6StunShspHandler;

  @override
  IShspSocketWrapper get ipv4ShspSocket => _ipv4StunShspHandler.shspSocket;

  @override
  IShspSocketWrapper get ipv6ShspSocket => _ipv6StunShspHandler.shspSocket;
}
