import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';

import 'package:stun_shsp/src/config/stun_shsp_config.dart';
import 'package:stun_shsp/src/implementations/stun_shsp_handler.dart';
import 'package:stun_shsp/src/interfaces/i_dual_stun_shsp_handler.dart';
import 'package:stun_shsp/src/interfaces/i_stun_shsp_handler.dart';
import 'package:stun_shsp/src/mixins/dual_stun_handler_delegation_mixin.dart';

/// A [DualShspSocketAuto] whose IPv4 and IPv6 sockets each get their own
/// [StunShspHandler], fanned out by one [DualStunHandler].
///
/// Every socket swap — [migrateSocket], [migrateSocketIpv4],
/// [migrateSocketIpv6], and therefore also [refreshSocket]/[refreshSockets],
/// which rebind and then migrate — rebuilds the combined handler for that
/// family, so its STUN state never refers to a socket that is gone.
///
/// Resolves its two sockets via DI — connect an `IShspSocketMigratable` under
/// the `'ipv4'`/`'ipv6'` subkeys (see `connectShspSocketMigratableSubkeys` in
/// the SHSP package) and call `dependencyInjectionFactory()`.
@dependencyInjectable
class DualStunShspHandler extends DualShspSocketAuto
    with DualStunHandlerDelegationMixin
    implements IDualStunShspHandler {
  // Spelled out instead of using super parameters: the DI generator reads the
  // declared parameter types to emit `dependencyInjectionFactory`, and drops
  // every parameter whose type it cannot see.
  // ignore: use_super_parameters
  DualStunShspHandler({
    @Subkey('ipv4') IShspSocketMigratable? ipv4Migratable,
    @Subkey('ipv6') IShspSocketMigratable? ipv6Migratable,
  }) : super(ipv4Migratable: ipv4Migratable, ipv6Migratable: ipv6Migratable) {
    _buildHandlers();
  }

  // ignore: avoid_unused_constructor_parameters, // GENERATED CODE - DO NOT MODIFY BY HAND
  factory DualStunShspHandler.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv4Migratable = RegistryManager.instance.tryGetInstance<IShspSocketMigratable>(key: key, subkey: 'ipv4'); // GENERATED CODE - DO NOT MODIFY BY HAND
    final ipv6Migratable = RegistryManager.instance.tryGetInstance<IShspSocketMigratable>(key: key, subkey: 'ipv6'); // GENERATED CODE - DO NOT MODIFY BY HAND

    return DualStunShspHandler( // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv4Migratable: ipv4Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
      ipv6Migratable: ipv6Migratable, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Wraps [sockets] into migratable sockets and builds a handler per family.
  DualStunShspHandler.fromSockets(super.sockets) : super.fromSockets() {
    _buildHandlers();
  }

  /// Binds an IPv4 and an IPv6 socket of its own.
  ///
  /// Unset ports fall back to the `socket` section of the `stun_shsp`
  /// configuration sector; see `StunShspConfigExtension`.
  static Future<DualStunShspHandler> createDefault({
    int? ipv4Port,
    int? ipv6Port,
    ICompressionCodec? compressionCodec,
  }) async {
    final ipv4Socket = await ShspSocket.bindDefault(
      ipv6: false,
      port: ipv4Port ?? defaultStunShspIpv4Port(),
      compressionCodec: compressionCodec,
    );
    final ipv6Socket = await ShspSocket.bindIfPossible(
      InternetAddress.anyIPv6,
      ipv6Port ?? defaultStunShspIpv6Port(),
      compressionCodec,
    );
    return DualStunShspHandler.fromSockets(
      Sockets(ipv4SocketImpl: ipv4Socket, ipv6SocketImpl: ipv6Socket),
    );
  }

  final DualStunHandler _dualStunHandler = DualStunHandler();
  final Map<InternetAddressType, IStunShspHandler> _handlers = {};

  @override
  IDualStunHandler get delegateDualStunHandler => _dualStunHandler;

  @override
  IDualStunHandler get dualStunHandler => _dualStunHandler;

  @override
  IStunShspHandler? getStunShspHandler([
    InternetAddressType type = InternetAddressType.IPv6,
  ]) => _handlers[type];

  @override
  IStunShspHandler? get ipv4StunShspHandler =>
      getStunShspHandler(InternetAddressType.IPv4);

  @override
  IStunShspHandler? get ipv6StunShspHandler =>
      getStunShspHandler(InternetAddressType.IPv6);

  @override
  void migrateSocket(
    IShspSocket socket, [
    InternetAddressType type = InternetAddressType.IPv6,
  ]) {
    super.migrateSocket(socket, type);
    _buildHandler(type);
  }

  @override
  void migrateSocketIpv4(IShspSocket socket) {
    super.migrateSocketIpv4(socket);
    _buildHandler(InternetAddressType.IPv4);
  }

  @override
  void migrateSocketIpv6(IShspSocket socket) {
    super.migrateSocketIpv6(socket);
    _buildHandler(InternetAddressType.IPv6);
  }

  /// Closes both halves; pass [type] to close a single address family.
  ///
  /// The STUN handlers and the sockets are the same endpoints seen from two
  /// sides, so closing one already closes the other — SHSP sockets are
  /// idempotent on close, which makes doing both explicitly safe.
  @override
  void close({InternetAddressType? type}) {
    _dualStunHandler.close(type: type);
    if (type == null) {
      super.close();
      return;
    }
    getSocket(type)?.close();
  }

  @override
  void destroy() {
    _dualStunHandler.destroy();
    super.destroy();
  }

  void _buildHandlers() {
    _buildHandler(InternetAddressType.IPv4);
    _buildHandler(InternetAddressType.IPv6);
  }

  /// (Re)builds the combined handler for [type] and hands it to the dual STUN
  /// handler, or clears that slot when the family has no socket bound.
  void _buildHandler(InternetAddressType type) {
    final socket = getSocket(type);
    if (socket == null) {
      _handlers.remove(type);
      _dualStunHandler.clearHandler(type: type);
      return;
    }
    final handler = StunShspHandler(getSocketMigratable(type));
    _handlers[type] = handler;
    _dualStunHandler.setHandler(handler, type: type);
  }
}
