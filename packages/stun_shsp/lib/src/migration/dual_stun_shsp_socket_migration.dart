import 'dart:io';

import 'package:singleton_manager/singleton_manager.dart';

import 'package:stun_shsp/src/interfaces/i_dual_stun_shsp_handler.dart';
import 'package:stun_shsp/src/interfaces/i_stun_shsp_handler.dart';
import 'package:stun_shsp/src/migration/stun_shsp_socket_migration.dart';

/// Migrates the ipv4 and/or ipv6 slots behind the [IDualStunShspHandler]
/// registered under [key] in one call, instead of calling
/// [migrateStunShspSocket] once per family by hand.
///
/// Pass whichever of [ipv4Socket]/[ipv6Socket] needs migrating — the other can
/// be left `null` to leave that family untouched. Each socket must actually be
/// bound to the family it's passed as (an IPv6 [ipv4Socket] throws
/// [ArgumentError]), since [migrateStunShspSocket] otherwise infers the subkey
/// from the socket itself and a mismatch would silently migrate the wrong
/// slot.
///
/// As with [migrateStunShspSocket], neither the dual handler nor the
/// per-family combined handlers are replaced: they route through the
/// `IShspSocketMigratable` wrappers, which is what actually gets repointed.
///
/// The per-family work goes through [migrateStunShspSocket], not through the
/// SHSP package's `migrateDualShspSockets`: that one resolves
/// `IDualShspSocketMigratable`, a slot this package's graph never needs to
/// build — here the dual router is the [IDualStunShspHandler] itself.
Future<({IStunShspHandler? ipv4, IStunShspHandler? ipv6})>
migrateDualStunShspSockets({
  RawDatagramSocket? ipv4Socket,
  RawDatagramSocket? ipv6Socket,
  String key = 'default',
}) async {
  if (ipv4Socket == null && ipv6Socket == null) {
    throw ArgumentError(
      'migrateDualStunShspSockets: pass at least one of '
      'ipv4Socket/ipv6Socket.',
    );
  }

  // Fetching the dual handler confirms one is actually registered under
  // [key] before anything is migrated.
  RegistryManager.instance.getInstance<IDualStunShspHandler>(key: key);

  if (ipv4Socket != null &&
      ipv4Socket.address.type != InternetAddressType.IPv4) {
    throw ArgumentError.value(
      ipv4Socket,
      'ipv4Socket',
      'must be bound to an IPv4 address, got ${ipv4Socket.address.type}.',
    );
  }
  if (ipv6Socket != null &&
      ipv6Socket.address.type != InternetAddressType.IPv6) {
    throw ArgumentError.value(
      ipv6Socket,
      'ipv6Socket',
      'must be bound to an IPv6 address, got ${ipv6Socket.address.type}.',
    );
  }

  return (
    ipv4: ipv4Socket == null
        ? null
        : await migrateStunShspSocket(ipv4Socket, key: key),
    ipv6: ipv6Socket == null
        ? null
        : await migrateStunShspSocket(ipv6Socket, key: key),
  );
}
