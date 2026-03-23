import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';

/// Interface for a handler combining STUN protocol with SHSP Socket
abstract interface class IStunShspHandler {
  bool get isInitialized;

  Future<void> initialize({
    String? address,
    int? port,
    Duration timeout,
    ICompressionCodec? compressionCodec,
  });

  Future<StunResponse> performStunRequest();

  Future<LocalInfo> performLocalRequest();

  Future<bool> pingStunServer({bool ipv6});

  void migrateSocketIpv4(IShspSocket socket);

  void migrateSocketIpv6(IShspSocket socket);

  void setStunServer(String address, int port, {bool? ipv6});

  IDualShspSocketMigratable get dualShspSocket;

  IShspSocket get ipv4ShspSocket;

  IShspSocket? get ipv6ShspSocket;

  StunHandlerBase get stunHandler;

  void close({bool? ipv6});
}
