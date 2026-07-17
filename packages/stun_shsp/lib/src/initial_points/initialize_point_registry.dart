// initialPointStunWithSocketsRegistry and IStunHandlerBase are not part of the
// stun package's public API (not exported from package:stun/stun.dart), but we
// need them to wire the registry-based initialization.
// ignore: implementation_imports
import 'package:stun/src/initial_point/initial_point_registry.dart';
import 'package:stun_shsp/stun_shsp.dart';

Future<void> initializePointRegistryStunShsp(String key) async {
  await initializePointRegistryAccess(key);

  await initialPointStunRegistry(key);

  final dualSocket = RegistryAccess.getInstance<IDualShspSocketMigratable>(key);
  final ipv4Socket = dualSocket.ipv4Socket;
  if (ipv4Socket != null) {
    final wrapper = ipv4Socket is IShspSocketWrapper
        ? ipv4Socket
        : ShspSocketWrapper(ipv4Socket);
    final handler = StunShspHandler(wrapper);
    RegistryAccess.register<IStunShspHandler>(key, handler);
  }
}
