import 'package:shsp/shsp.dart';
import 'package:stun/stun.dart';

/// A migratable SHSP socket that also answers STUN on that very same socket.
///
/// Being an [IShspSocketMigratable] it can be handed to anything in the SHSP
/// package that takes a socket (peers, instances, dual sockets); being an
/// [IStunHandler] it can be handed to anything in the STUN package that takes
/// a handler — both halves share one bound port, which is the point of the
/// combination.
abstract interface class IStunShspHandler
    implements IStunHandler, IShspSocketMigratable {
  /// The STUN half, to reach members this interface cannot expose.
  IStunHandler get stunHandler;

  /// The SHSP half, i.e. the socket the STUN half is bound to.
  IShspSocketMigratable get shspSocket;
}
