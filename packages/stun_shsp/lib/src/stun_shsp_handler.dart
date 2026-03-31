import 'dart:io';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
import 'package:shsp/shsp.dart';
import 'i_stun_shsp_handler.dart';

export 'i_stun_shsp_handler.dart';

/// Base handler combining STUN protocol with SHSP Socket for NAT traversal + data communication
///
/// This class provides:
/// - Automatic STUN-based NAT detection (IPv4/IPv6)
/// - SHSP protocol support with message compression
/// - Unified socket management across both protocols
///
/// Example:
/// ```dart
/// final handler = StunShspHandler();
/// await handler.initialize(address: '0.0.0.0', port: 5000);
///
/// // Get STUN information
/// final stunResponse = await handler.performStunRequest();
///
/// // Use SHSP socket for communication
/// final shspSocket = handler.dualShspSocket;
/// ```
@isSingleton
class StunShspHandler with ValueForRegistry implements IStunShspHandler {
  StunShspHandler();

  /// Underlying STUN handler singleton
  @isInjected
  late StunHandlerBase _stunHandler;

  /// Unified dual SHSP socket (handles both IPv4 and IPv6)
  @isInjected
  late IDualShspSocketMigratable _dualShspSocket;

  bool _initialized = false;

  /// Whether [initialize] or [injectDependencies] has already been called.
  @override
  bool get isInitialized => _initialized;

  /// Injection point used by the generated DI class.
  /// Not for direct use — call [initialize] or use the DI system instead.
  void injectDependencies({
    required StunHandlerBase stunHandler,
    required IDualShspSocketMigratable dualShspSocket,
  }) {
    _initialized = true;
    _stunHandler = stunHandler;
    _dualShspSocket = dualShspSocket;
  }

  /// Initialize STUN handlers and SHSP sockets
  ///
  /// Creates both IPv4 and IPv6 STUN handlers along with corresponding SHSP sockets.
  /// IPv6 is optional and fails gracefully if unavailable.
  ///
  /// Throws [StateError] if already initialized (either via this method or [injectDependencies]).
  @override
  Future<void> initialize({
    String? address,
    int? port,
    Duration timeout = const Duration(seconds: 5),
    ICompressionCodec? compressionCodec,
  }) async {
    if (_initialized) {
      throw StateError(
        'StunShspHandler is already initialized. '
        'Do not mix initialize() with injectDependencies().',
      );
    }
    _initialized = true;

    // Create STUN handler singleton (must be done before using it)
    _stunHandler = StunHandlerSingleton();

    // Initialize STUN handlers
    await _stunHandler.initialize(
      address: address,
      port: port,
      timeout: timeout,
    );

    // Create SHSP sockets
    final bindAddress =
        address != null ? InternetAddress(address) : InternetAddress.anyIPv4;
    final bindPort = port ?? 0;

    // Create IPv4 socket (required)
    final ShspSocket ipv4Socket = await ShspSocket.bind(
      bindAddress,
      bindPort,
      compressionCodec,
    );

    // Create IPv6 socket (fails gracefully)
    ShspSocket? ipv6Socket;
    try {
      final ipv6Address = address != null
          ? InternetAddress(address, type: InternetAddressType.IPv6)
          : InternetAddress.anyIPv6;
      ipv6Socket = await ShspSocket.bind(
        ipv6Address,
        bindPort,
        compressionCodec,
      );
    } catch (e) {
      ipv6Socket = null;
    }

    // Create unified dual socket
    _dualShspSocket = DualShspSocketMigratable(ipv4Socket, ipv6Socket);
  }

  /// Perform STUN request to detect NAT
  @override
  Future<StunResponse> performStunRequest() async {
    return _stunHandler.performStunRequest();
  }

  /// Perform local address detection
  @override
  Future<LocalInfo> performLocalRequest() async {
    return _stunHandler.performLocalRequest();
  }

  /// Ping STUN server
  @override
  Future<bool> pingStunServer({bool ipv6 = false}) async {
    return _stunHandler.pingStunServer(ipv6: ipv6);
  }

  /// Set STUN server
  @override
  void setStunServer(String address, int port, {bool? ipv6}) {
    _stunHandler.setStunServer(address, port, ipv6: ipv6);
  }

  /// Get the unified dual SHSP socket (handles both IPv4 and IPv6 with automatic routing)
  @override
  IDualShspSocketMigratable get dualShspSocket => _dualShspSocket;

  /// Get IPv4 SHSP socket (backwards compatibility)
  @override
  IShspSocket get ipv4ShspSocket => _dualShspSocket.ipv4Socket;

  /// Get IPv6 SHSP socket (may be null if not available)
  @override
  IShspSocket? get ipv6ShspSocket => _dualShspSocket.ipv6Socket;

  /// Get STUN handler for advanced usage
  @override
  StunHandlerBase get stunHandler => _stunHandler;

  /// Close all resources
  @override
  void close({bool? ipv6}) {
    _stunHandler.close(ipv6: ipv6);
    _dualShspSocket.close();
  }

  @override
  void destroy() => close();

  @override
  void migrateSocketIpv4(IShspSocket socket) {
    _dualShspSocket.migrateSocketIpv4(socket);
  }

  @override
  void migrateSocketIpv6(IShspSocket socket) {
    _dualShspSocket.migrateSocketIpv6(socket);
  }
}
