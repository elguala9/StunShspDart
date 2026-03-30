# stun_shsp

A Dart package that combines the [STUN](https://pub.dev/packages/stun) and [SHSP](https://pub.dev/packages/shsp) protocols into a single unified handler for NAT traversal and peer-to-peer data communication.

## Features

- **NAT traversal** via STUN (RFC 5389) — discover your public IP and port
- **Dual-stack** IPv4 + IPv6 support with graceful IPv6 fallback
- **SHSP socket** for compressed, structured UDP communication
- **Socket migration** — swap IPv4/IPv6 sockets at runtime without tearing down the handler
- **Dependency injection** via `singleton_manager` with a generated DI class
- **Singleton pattern** — `StunShspHandlerSingleton` ensures one instance per process
- **One-call initialization** via `initializePointStunShsp()`

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  stun_shsp: ^0.1.2
```

Then run:

```sh
dart pub get
```

## Usage

### Quick start with DI (recommended)

Initialize all dependencies in one call and resolve via `SingletonDIAccess`:

```dart
import 'package:stun_shsp/stun_shsp.dart';

Future<void> main() async {
  // Initialize SHSP sockets, STUN handlers and DI wiring
  await initializePointStunShsp();

  final handler = SingletonDIAccess.get<IStunShspHandler>();

  // Discover public IP / port via STUN
  final stunResponse = await handler.performStunRequest();
  print('Public address: ${stunResponse.publicIp}:${stunResponse.publicPort}');

  // Use the SHSP socket for peer communication
  final socket = handler.dualShspSocket;
  // ...

  handler.close();
}
```

### Manual instantiation

```dart
import 'package:stun_shsp/stun_shsp.dart';

final handler = StunShspHandlerSingleton();

await handler.initialize(
  address: '0.0.0.0',
  port: 5000,
  timeout: Duration(seconds: 5),
  compressionCodec: MyCodec(), // optional
);

// NAT detection
final stunResponse = await handler.performStunRequest();
print('Public IP: ${stunResponse.publicIp}');
print('Public port: ${stunResponse.publicPort}');

// Local address info
final localInfo = await handler.performLocalRequest();
print('Local address: ${localInfo.address}:${localInfo.port}');

// IPv4 socket
final ipv4Socket = handler.ipv4ShspSocket;

// IPv6 socket (null when IPv6 is unavailable on the system)
final ipv6Socket = handler.ipv6ShspSocket;

// Dual socket — routes automatically between IPv4/IPv6
final dual = handler.dualShspSocket;

handler.close();
```

### Socket migration

Replace a running socket without recreating the handler:

```dart
final newSocket = await ShspSocket.bind(InternetAddress.anyIPv4, 0);
handler.migrateSocketIpv4(newSocket);

final newIpv6Socket = await ShspSocket.bind(InternetAddress.anyIPv6, 0);
handler.migrateSocketIpv6(newIpv6Socket);
```

### Custom STUN server

```dart
handler.setStunServer('stun.example.com', 3478);
handler.setStunServer('stun6.example.com', 3478, ipv6: true);

final ok = await handler.pingStunServer();
```

## API

### `initializePointStunShsp()`

Bootstraps the full dependency graph:
1. Initializes dual SHSP sockets (`initializePointDualShsp`)
2. Initializes STUN handlers bound to those sockets
3. Creates and registers `StunShspHandlerDI` in the DI container

After this call you can resolve `IStunShspHandler` from `SingletonDIAccess`.

---

### `IStunShspHandler`

| Member | Description |
|---|---|
| `initialize({address, port, timeout, compressionCodec})` | Bind sockets and prepare handlers |
| `performStunRequest()` | Query STUN server, returns `StunResponse` |
| `performLocalRequest()` | Returns `LocalInfo` (local address/port) |
| `pingStunServer({ipv6})` | Checks reachability of configured STUN server |
| `setStunServer(address, port, {ipv6})` | Override STUN server address |
| `migrateSocketIpv4(socket)` | Swap the active IPv4 `IShspSocket` |
| `migrateSocketIpv6(socket)` | Swap the active IPv6 `IShspSocket` |
| `dualShspSocket` | The `IDualShspSocketMigratable` unified socket |
| `ipv4ShspSocket` | Direct access to the IPv4 `IShspSocket` |
| `ipv6ShspSocket` | Direct access to the IPv6 `IShspSocket` (nullable) |
| `stunHandler` | Underlying `StunHandlerBase` for advanced use |
| `close({ipv6})` | Close sockets and release resources |

---

### `StunShspHandler`

Concrete implementation of `IStunShspHandler`. Annotated with `@isSingleton` for DI code generation. Accepts injected dependencies via `injectDependencies(...)`.

---

### `StunShspHandlerSingleton`

Extends `StunShspHandler` with a Dart singleton factory:

```dart
final a = StunShspHandlerSingleton();
final b = StunShspHandlerSingleton();
assert(identical(a, b)); // true
```

---

### `StunShspHandlerDI` (generated)

Auto-generated class in `lib/generated/stun_shsp_handler_di.dart`. Implements `ISingletonStandardDI` and resolves dependencies from `SingletonDIAccess` at construction time. Do not instantiate directly — use `initializePointStunShsp()` instead.

## Dependencies

| Package | Role |
|---|---|
| [`stun`](https://pub.dev/packages/stun) | STUN protocol, NAT detection |
| [`shsp`](https://pub.dev/packages/shsp) | Structured UDP socket with optional compression |
| [`singleton_manager`](https://pub.dev/packages/singleton_manager) | DI container and singleton lifecycle |

## License

MIT
