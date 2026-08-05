import 'dart:io';

import 'package:shsp/shsp.dart';
import 'package:stun/stun.dart';

import 'i_stun_shsp_handler.dart';

/// A dual-stack SHSP socket whose two families also answer STUN.
///
/// It is an [IDualShspSocketAuto] — a router over an IPv4 and an IPv6 socket,
/// not a socket itself — so it can be passed anywhere SHSP expects a dual
/// socket. It is *not* an [IDualStunHandler], because that interface and
/// `IDualShspSocket` declare incompatible `getSocket` members; the dual STUN
/// handler is exposed as [dualStunHandler] instead, and the rest of its
/// surface is forwarded by `DualStunHandlerDelegationMixin`.
abstract interface class IDualStunShspHandler implements IDualShspSocketAuto {
  /// The STUN half: one handler per address family, fanning requests out.
  IDualStunHandler get dualStunHandler;

  /// The combined handler for [type], or `null` when that family has no
  /// socket bound.
  IStunShspHandler? getStunShspHandler([
    InternetAddressType type = InternetAddressType.IPv6,
  ]);

  /// The combined IPv4 handler, or `null` when no IPv4 socket is bound.
  IStunShspHandler? get ipv4StunShspHandler;

  /// The combined IPv6 handler, or `null` when no IPv6 socket is bound.
  IStunShspHandler? get ipv6StunShspHandler;
}
