import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';

import 'package:stun_shsp/src/interfaces/i_stun_shsp_handler.dart';

/// Migrates the combined handler registered under [key] onto [socket],
/// resolving which subkey ('ipv4'/'ipv6') to target straight from the
/// socket's own address family — same rule as the SHSP and STUN packages, so
/// [shspSocketSubkeyFor] is reused rather than re-implemented here.
///
/// The [IStunShspHandler] already registered for that (key, subkey) is never
/// replaced: it holds the [IShspSocketMigratable] — not the socket behind it —
/// and its STUN half is built on that same wrapper, so repointing the wrapper
/// moves both halves at once. That repointing, plus overwriting the
/// `RawDatagramSocket`/`IShspSocket` registry entries, is exactly what
/// [migrateShspSocket] already does, so this call delegates to it.
///
/// When the STUN graph is wired under [key] as well (it is, with
/// `StunShspInjector`/`initializeStunShsp`), the plain `IStunHandler` entry
/// for the same subkey is refreshed too, via the STUN package's own
/// [migrateStunHandlerSocket] — otherwise anything resolving `IStunHandler`
/// from the registry would keep a handler bound to the socket that was just
/// closed. Graphs without `IStunHandlerMigratable` connected simply skip that
/// step.
///
/// Returns the (unchanged) combined handler now serving [socket].
Future<IStunShspHandler> migrateStunShspSocket(
  RawDatagramSocket socket, {
  String key = 'default',
}) async {
  final subkey = shspSocketSubkeyFor(socket.address.type);

  // Resolved before anything moves: it fails fast when no combined handler is
  // registered for this slot, and it makes sure the handler exists while the
  // old socket is still in place, so the wrapper it delegates to is the one
  // being migrated.
  final handler = RegistryManager.instance.getInstance<IStunShspHandler>(
    key: key,
    subkey: subkey,
  );

  await migrateShspSocket(socket, key: key);

  migrateStunHandlerEntry(socket, key: key);

  return handler;
}

/// Refreshes the plain `IStunHandler` registry entry for the subkey matching
/// [socket]'s family, when the STUN graph is wired under [key].
///
/// Best effort by design: a stun_shsp graph is usable with only the SHSP
/// singletons and `connectStunShspHandlerSubkeys` connected, in which case no
/// `IStunHandlerMigratable` exists to migrate and there is no plain
/// `IStunHandler` entry that could go stale either.
///
/// Kept public so a caller that swapped a socket by hand — through
/// `IStunShspHandler.migrateSocket` or `DualStunShspHandler.refreshSocket`,
/// which never touch the registry — can bring the STUN entries back in line.
void migrateStunHandlerEntry(RawDatagramSocket socket, {String key = 'default'}) {
  final subkey = shspSocketSubkeyFor(socket.address.type);
  final migratable = RegistryManager.instance
      .tryGetInstance<IStunHandlerMigratable>(key: key, subkey: subkey);
  if (migratable == null) return;

  migrateStunHandlerSocket(socket, key: key);
}

/// Binds a fresh IPv4 socket and migrates the ipv4 slot onto it.
Future<IStunShspHandler> migrateStunShspSocketIpv4({
  String key = 'default',
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  return migrateStunShspSocket(socket, key: key);
}

/// Binds a fresh IPv6 socket and migrates the ipv6 slot onto it.
Future<IStunShspHandler> migrateStunShspSocketIpv6({
  String key = 'default',
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv6, 0);
  return migrateStunShspSocket(socket, key: key);
}
