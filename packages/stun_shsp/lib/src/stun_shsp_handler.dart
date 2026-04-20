import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun/stun.dart';
// StunMessage is internal to the stun package but needed to build/parse STUN
// requests on an externally-managed socket (the SHSP socket).
// ignore: implementation_imports
import 'package:stun/src/implementations/request/stun_message.dart';
import 'package:shsp/shsp.dart';
import 'i_stun_shsp_handler.dart';

export 'i_stun_shsp_handler.dart';

/// Default STUN server used when none is configured.
const String _kDefaultStunHost = 'stun.l.google.com';
const int _kDefaultStunPort = 19302;

/// Base handler combining STUN protocol with SHSP Socket for NAT traversal + data communication
///
/// This class provides:
/// - STUN-based NAT detection that runs **on the same UDP socket as SHSP**.
///   The public port returned by [performStunRequest] therefore matches the port
///   that P2P peers must use to reach this node — no mismatch with [dualShspSocket].
/// - SHSP protocol support with message compression
/// - Unified socket management across both protocols
///
/// Example:
/// ```dart
/// final handler = StunShspHandler();
/// await handler.initialize(address: '0.0.0.0', port: 5000);
///
/// // Get STUN information (NAT mapping for the SHSP socket's port)
/// final stunResponse = await handler.performStunRequest();
///
/// // Use SHSP socket for communication
/// final shspSocket = handler.dualShspSocket;
/// ```
@isSingleton
class StunShspHandler with ValueForRegistry implements IStunShspHandler {
  StunShspHandler();

  /// Underlying STUN handler singleton (used for DI wiring, setStunServer, ping)
  @isInjected
  late StunHandlerBase _stunHandler;

  /// Unified dual SHSP socket (handles both IPv4 and IPv6)
  @isInjected
  late IDualShspSocketMigratable _dualShspSocket;

  bool _initialized = false;

  // ── STUN server configuration ────────────────────────────────────────────
  String _stunHost = _kDefaultStunHost;
  int _stunPort = _kDefaultStunPort;
  Duration _stunTimeout = const Duration(seconds: 5);

  // Per-socket cached responses (set after the first successful request)
  StunResponse? _cachedIpv4StunResponse;

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

  /// Initialize STUN handlers and SHSP sockets.
  ///
  /// Creates both IPv4 and IPv6 SHSP sockets; IPv6 is optional and fails
  /// gracefully if unavailable. STUN handlers are wired to the same underlying
  /// sockets so that NAT discovery always reflects the port peers must reach.
  ///
  /// Throws [StateError] if already initialized (either via this method or
  /// [injectDependencies]).
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
    _stunTimeout = timeout;

    _stunHandler = StunHandlerSingleton();

    final bindAddress =
        address != null ? InternetAddress(address) : InternetAddress.anyIPv4;
    final bindPort = port ?? 0;

    // ── IPv4 (required) ──────────────────────────────────────────────────────
    // Bind the raw socket first so STUN probes the EXACT port SHSP will use.
    final rawIpv4 = await RawDatagramSocket.bind(
      bindAddress,
      bindPort,
      reuseAddress: true,
    );
    final ipv4LocalPort = rawIpv4.port;

    // Wire a STUN handler to this socket.  We call initializeWithHandlers()
    // later; the handler is used only for DI / ping — actual STUN requests go
    // through _performStunViaShsp() to avoid the single-subscription conflict.
    final ipv4StunHandler = StunHandler.withSocket(rawIpv4, timeout: timeout);

    // Release the raw socket so SHSP can bind a fresh socket on the same port.
    // UDP sockets have no TIME_WAIT, so the port is immediately reusable.
    rawIpv4.close();

    final ipv4Socket = await ShspSocket.bind(
      bindAddress,
      ipv4LocalPort,
      compressionCodec,
    );

    // ── IPv6 (optional) ──────────────────────────────────────────────────────
    ShspSocket? ipv6Socket;
    IStunHandler? ipv6StunHandler;
    try {
      final ipv6Address = address != null
          ? InternetAddress(address, type: InternetAddressType.IPv6)
          : InternetAddress.anyIPv6;
      final rawIpv6 = await RawDatagramSocket.bind(
        ipv6Address,
        bindPort,
        reuseAddress: true,
      );
      final ipv6LocalPort = rawIpv6.port;

      ipv6StunHandler = StunHandler.withSocket(rawIpv6, timeout: timeout);
      rawIpv6.close();

      ipv6Socket = await ShspSocket.bind(
        ipv6Address,
        ipv6LocalPort,
        compressionCodec,
      );
    } catch (_) {
      ipv6Socket = null;
      ipv6StunHandler = null;
    }

    // Wire STUN handlers into the singleton base (for DI / ping / setStunServer).
    await _stunHandler.initializeWithHandlers(
      ipv4StunHandler,
      ipv6Handler: ipv6StunHandler,
    );

    _dualShspSocket = DualShspSocketMigratable(ipv4Socket, ipv6Socket);
  }

  // ── STUN public API ────────────────────────────────────────────────────────

  /// Perform STUN request to discover the public NAT mapping for the SHSP socket.
  ///
  /// The request is sent **from the SHSP socket** so the discovered public port
  /// matches the port that peers must connect to. Results are cached; subsequent
  /// calls return the cached value instantly.
  @override
  Future<StunResponse> performStunRequest() async {
    _cachedIpv4StunResponse ??=
        await _performStunViaShsp(_dualShspSocket.ipv4Socket, ipv6: false);
    return _cachedIpv4StunResponse!;
  }

  /// Perform local address detection using the SHSP socket's actual local port.
  @override
  Future<LocalInfo> performLocalRequest() async {
    final shspPort = _dualShspSocket.ipv4Socket.localPort ?? 0;
    final localIp = await _resolveLocalIp(InternetAddressType.IPv4);
    return (localIp: localIp, localPort: shspPort);
  }

  /// Ping STUN server
  @override
  Future<bool> pingStunServer({bool ipv6 = false}) async {
    try {
      if (ipv6) {
        final ipv6Socket = _dualShspSocket.ipv6Socket;
        if (ipv6Socket == null) return false;
        await _performStunViaShsp(ipv6Socket, ipv6: true);
      } else {
        await _performStunViaShsp(_dualShspSocket.ipv4Socket, ipv6: false);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Set STUN server — applies to future [performStunRequest] calls.
  @override
  void setStunServer(String address, int port, {bool? ipv6}) {
    _stunHost = address;
    _stunPort = port;
    // Also update the underlying handler (used for ping / DI consumers).
    _stunHandler.setStunServer(address, port, ipv6: ipv6);
    // Invalidate cached responses so the next request uses the new server.
    _cachedIpv4StunResponse = null;
  }

  // ── Socket accessors ───────────────────────────────────────────────────────

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

  // ── Internal: STUN-over-SHSP ───────────────────────────────────────────────

  /// Performs a STUN Binding Request **via [shspSocket]** so that the STUN
  /// server sees the same source port that peers use for P2P data.
  ///
  /// The STUN exchange is done at the raw UDP level (bypassing SHSP
  /// compression on the send path) while receiving the response through
  /// SHSP's existing subscription via a registered message callback.
  Future<StunResponse> _performStunViaShsp(
    IShspSocket shspSocket, {
    required bool ipv6,
  }) async {
    final addrType =
        ipv6 ? InternetAddressType.IPv6 : InternetAddressType.IPv4;
    final addrs = await InternetAddress.lookup(_stunHost, type: addrType);
    if (addrs.isEmpty) {
      throw StateError('Cannot resolve STUN server: $_stunHost');
    }
    final serverAddr = addrs.first;
    final serverPeer = PeerInfo(address: serverAddr, port: _stunPort);

    // Build the raw STUN Binding Request.
    final request = StunMessage.createBindingRequest();
    final requestBytes = request.toBytes();

    final completer = Completer<StunResponse>();

    void callback(MessageRecord record) {
      if (completer.isCompleted) return;
      try {
        final response =
            StunMessage.fromBytes(Uint8List.fromList(record.msg));
        final xorMapped = response.getXorMappedAddress();
        if (xorMapped != null) {
          completer.complete((
            publicIp: xorMapped.ip,
            publicPort: xorMapped.port,
            ipVersion: ipv6 ? IpVersion.v6 : IpVersion.v4,
            transactionId: response.transactionId,
            raw: Uint8List.fromList(record.msg),
            attrs: null,
          ));
        }
      } catch (_) {
        // Packet was not a valid STUN response — ignore it.
      }
    }

    shspSocket.setMessageCallback(serverPeer, callback);

    try {
      // Send the raw STUN bytes directly on the underlying UDP socket,
      // bypassing SHSP's compression layer (STUN server expects raw bytes).
      shspSocket.socket.send(requestBytes, serverAddr, _stunPort);

      return await completer.future.timeout(
        _stunTimeout,
        onTimeout: () => throw TimeoutException(
          'STUN request timed out after ${_stunTimeout.inSeconds}s',
          _stunTimeout,
        ),
      );
    } finally {
      shspSocket.removeMessageCallback(serverPeer, callback);
    }
  }

  /// Returns a non-loopback local IP for the given [addrType].
  Future<String> _resolveLocalIp(InternetAddressType addrType) async {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: addrType,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return addrType == InternetAddressType.IPv6
        ? InternetAddress.loopbackIPv6.address
        : InternetAddress.loopbackIPv4.address;
  }
}
