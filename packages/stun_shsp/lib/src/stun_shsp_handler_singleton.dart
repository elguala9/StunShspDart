import 'stun_shsp_handler.dart';

export 'stun_shsp_handler.dart';

/// Singleton handler combining STUN protocol with SHSP Socket for NAT traversal + data communication
///
/// Extends [StunShspHandler] with a singleton pattern to ensure only one instance exists.
///
/// Example:
/// ```dart
/// final handler = StunShspHandlerSingleton();
/// await handler.initialize(address: '0.0.0.0', port: 5000);
///
/// // Get STUN information
/// final stunResponse = await handler.performStunRequest();
///
/// // Use SHSP socket for communication
/// final shspSocket = handler.getShspSocket();
/// shspSocket.setMessageCallback(peer, (record) {
///   print('Message from ${record.rinfo}: ${record.msg}');
/// });
/// ```
class StunShspHandlerSingleton extends StunShspHandler {
  /// Factory constructor - ensures only one instance exists
  factory StunShspHandlerSingleton() => _instance;

  /// Private constructor for singleton pattern
  StunShspHandlerSingleton._internal() : super();

  static final StunShspHandlerSingleton _instance =
      StunShspHandlerSingleton._internal();

  /// Get the singleton instance
  static StunShspHandlerSingleton get instance => _instance;
}
