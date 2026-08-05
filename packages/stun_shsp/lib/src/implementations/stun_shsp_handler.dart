import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';

import 'package:stun_shsp/src/config/stun_shsp_config.dart';
import 'package:stun_shsp/src/interfaces/i_stun_shsp_handler.dart';
import 'package:stun_shsp/src/mixins/stun_handler_delegation_mixin.dart';

/// One SHSP socket, one STUN handler bound to it.
///
/// The STUN handler is built on the [IShspSocketMigratable] itself rather than
/// on the socket behind it, so a [migrateSocket] swaps the socket under both
/// halves at once and the handler keeps working against the new one.
///
/// Resolves [shspSocket] via DI — connect an `IShspSocketMigratable` into
/// [RegistryManager] under the `'ipv4'`/`'ipv6'` subkey (see
/// `connectStunShspHandlerSubkeys`) and call `dependencyInjectionFactory()`:
/// ```dart
/// final handler = StunShspHandler.dependencyInjectionFactory(subkey: 'ipv4');
/// ```

class StunShspHandler
    with ShspSocketMigratableDelegationMixin, StunHandlerDelegationMixin
    implements IStunShspHandler {
  /// Unset STUN arguments fall back to the STUN configuration of the `stun`
  /// package (see `StunConfigExtension`).
  StunShspHandler(
    IShspSocketMigratable shspSocket, {
    String? address,
    int? port,
    Duration? timeout,
    void Function(String)? onLog,
  }) : _shspSocket = shspSocket,
       _stunHandler = StunHandler(
         shspSocket,
         address: address,
         port: port,
         timeout: timeout,
         onLog: onLog,
       );

  factory StunShspHandler.dependencyInjectionFactory({String key = 'default', String subkey = 'default'}) { // GENERATED CODE - DO NOT MODIFY BY HAND
    final shspSocket = RegistryManager.instance.getInstance<IShspSocketMigratable>(key: key, subkey: subkey); // GENERATED CODE - DO NOT MODIFY BY HAND
    final address = RegistryManager.instance.tryGetInstance<String>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final port = RegistryManager.instance.tryGetInstance<int>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND
    final timeout = RegistryManager.instance.tryGetInstance<Duration>(key: key); // GENERATED CODE - DO NOT MODIFY BY HAND

    return StunShspHandler( // GENERATED CODE - DO NOT MODIFY BY HAND
      shspSocket, // GENERATED CODE - DO NOT MODIFY BY HAND
      address: address, // GENERATED CODE - DO NOT MODIFY BY HAND
      port: port, // GENERATED CODE - DO NOT MODIFY BY HAND
      timeout: timeout, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  final IStunHandler _stunHandler;
  final IShspSocketMigratable _shspSocket;

  /// Binds a socket of its own and wraps it.
  ///
  /// Unset arguments fall back to the configuration: [port] to the `socket`
  /// section of the `stun_shsp` sector, [ipv6] and the STUN arguments to the
  /// `stun` sector, which owns them; see [StunShspConfigExtension].
  static Future<StunShspHandler> createDefault({
    bool? ipv6,
    int? port,
    ICompressionCodec? compressionCodec,
    String? address,
    int? stunPort,
    Duration? timeout,
  }) async {
    final socket = await ShspSocket.bindDefault(
      ipv6: ipv6 ?? defaultStunShspIpv6Enabled(),
      port: port ?? defaultStunShspPort(),
      compressionCodec: compressionCodec,
    );
    return StunShspHandler(
      ShspSocketMigratable(socket),
      address: address,
      port: stunPort,
      timeout: timeout,
    );
  }

  @override
  IShspSocket get delegateSocket => _shspSocket;

  @override
  IStunHandler get delegateStunHandler => _stunHandler;

  @override
  IStunHandler get stunHandler => _stunHandler;

  @override
  IShspSocketMigratable get shspSocket => _shspSocket;

  @override
  void migrateSocket(IShspSocket socket) => _shspSocket.migrateSocket(socket);

  /// Closes the STUN handler and the socket. Both halves own the same socket,
  /// so either call alone would already close it; SHSP sockets are
  /// idempotent on close, hence doing both explicitly is safe.
  @override
  void close() {
    _stunHandler.close();
    _shspSocket.close();
  }

  @override
  void destroy() {
    _stunHandler.close();
    _shspSocket.destroy();
  }

  @override
  InternetAddressType getIpVersion() => _stunHandler.getIpVersion();
}
