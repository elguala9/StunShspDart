# stun_shsp

A Dart package that combines the [STUN](https://pub.dev/packages/stun) and [SHSP](https://pub.dev/packages/shsp) protocols: one bound UDP port that both answers STUN and carries SHSP traffic, so the public address STUN discovers is exactly the one peers must use.

## Features

- **NAT traversal** via STUN (RFC 5389) — on the same socket the data flows through
- **Dual-stack** IPv4 + IPv6, each family with its own handler, requests fanned out over both
- **SHSP socket** for compressed, structured UDP communication
- **Socket migration** — swap a socket at runtime and both halves follow it
- **NAT compatibility check** — `NATDetectorShsp` tells you whether the detected NAT type can carry SHSP at all
- **Configuration** through [`config_manager`](https://pub.dev/packages/config_manager), in the `stun_shsp` sector
- **Dependency injection** through [`singleton_manager`](https://pub.dev/packages/singleton_manager), with generated factories and one-call wiring

## Installation

```yaml
dependencies:
  stun_shsp: ^0.4.0
```

```sh
dart pub get
```

## Usage

### Quick start

```dart
import 'package:stun_shsp/stun_shsp.dart';

Future<void> main() async {
  // One socket, both protocols.
  final handler = await StunShspHandler.createDefault(ipv6: false);

  final response = await handler.performStunRequest();
  final type = handler.getIpVersion();
  print('public: ${response.publicIp(type)}:${response.publicPort(type)}');
  print('local:  ${handler.localAddress}:${handler.localPort}');

  // The same object is an SHSP socket — hand it to peers, instances, ...
  handler.setMessageCallback(peer, (message) => print(message.msg));

  handler.close();
}
```

### Dual stack

`DualStunShspHandler` is a `DualShspSocketAuto` that builds a `StunShspHandler` per address family and fans STUN requests out over both:

```dart
final dual = await DualStunShspHandler.createDefault();

final response = await dual.performStunRequest();
print('v4: ${response.publicIp(InternetAddressType.IPv4)}');
print('v6: ${response.publicIp(InternetAddressType.IPv6)}');

// Per-family access
final v4 = dual.ipv4StunShspHandler;          // IStunShspHandler?
final v6Socket = dual.getSocket(InternetAddressType.IPv6);  // IShspSocket?

// The STUN half as one handler
final stun = dual.dualStunHandler;            // IDualStunHandler

dual.close(type: InternetAddressType.IPv4);   // one family
dual.destroy();                               // everything
```

It is deliberately **not** an `IDualStunHandler`: that interface and `IDualShspSocket` declare incompatible `getSocket` members, so `getSocket` keeps its SHSP meaning and the STUN socket is reached through `dual.dualStunHandler.getSocket(type: ...)`. Everything else of the STUN surface is forwarded by `DualStunHandlerDelegationMixin`.

### Dependency injection

`initializeStunShsp` wires all three graphs under one key: SHSP first (which binds the ipv4/ipv6 sockets), then STUN, then this package's singletons.

```dart
await initializeStunShsp();

final registry = RegistryManager.instance;
final ipv4 = registry.getInstance<IStunShspHandler>(subkey: 'ipv4');
final dual = registry.getInstance<IDualStunShspHandler>();

// The per-family handler and the dual one share the same socket.
assert(identical(
  ipv4.shspSocket,
  dual.getSocketMigratable(InternetAddressType.IPv4),
));
```

The raw sockets are bound once, by the SHSP side, so everything in the registry sits on the same endpoint:

```dart
final raw  = registry.getInstance<RawDatagramSocket>(subkey: 'ipv4');
final stun = registry.getInstance<IStunHandler>(subkey: 'ipv4');   // stun package
assert(stun.getSocket().port == raw.port);
assert(stun.getSocket().port == ipv4.localPort);
```

That is why `DualStunInjector` from the STUN package is *not* used: it would bind new sockets of its own and overwrite those connections.

Every call is independent, so several graphs can live side by side under different keys (`initializeStunShsp(key: 'peer-a')`). If the application already wired the SHSP graph itself, use the synchronous `StunShspInjector().registerAllSingletonsStunShsp(key: ...)`, or `connectStunShspHandlerSubkeys` for just the per-family handlers.

### Socket migration

```dart
final newSocket = await ShspSocket.bindDefault(ipv6: false);
handler.migrateSocket(newSocket);

// The STUN half is built on the migratable socket, so it follows the swap:
assert(handler.getSocket().port == newSocket.localPort);
```

On the dual handler, `migrateSocket`, `migrateSocketIpv4`, `migrateSocketIpv6` — and therefore `refreshSocket`/`refreshSockets`, which rebind and then migrate — rebuild the combined handler of that family, so its STUN state never points at a socket that is gone.

#### Migrating a wired graph

Those calls only touch the instance they are made on. For a graph wired through `initializeStunShsp`, the registry-level functions swap the socket *and* the registry entries in one go — the same pair the `shsp` and `stun` packages offer (`migrateShspSocket`, `migrateStunHandlerSocket`), which is exactly what these delegate to:

```dart
await initializeStunShsp();

final raw = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
final handler = await migrateStunShspSocket(raw);          // subkey from raw.address.type

// Or both families at once, and let it bind the socket itself:
await migrateDualStunShspSockets(ipv4Socket: raw, ipv6Socket: ipv6Raw);
final ipv4 = await migrateStunShspSocketIpv4();
final ipv6 = await migrateStunShspSocketIpv6();
```

Nothing that routes is replaced: the registered `IStunShspHandler`, the `IShspSocketMigratable` it is built on and the `IDualStunShspHandler` all stay put — only the `RawDatagramSocket`/`IShspSocket` entries move, and the old socket is closed with its callbacks carried over. The plain `IStunHandler` entry of the STUN graph is refreshed too (via `migrateStunHandlerSocket`), so nothing resolves a STUN handler bound to the closed socket; a graph wired without the STUN half simply skips that step. After a hand-made swap (`migrateSocket`, `refreshSocket`), `migrateStunHandlerEntry(socket)` brings those entries back in line on its own.

### Configuration

Defaults live in the `stun_shsp` sector of `config_manager`, next to the `stun` and `shsp` sectors owned by those packages. Nothing has to be loaded: every getter falls back to `defaultStunShspConfig`.

```dart
initStunShspConfig({
  'socket': {'ipv6': false, 'port': 5000},
  'nat': {'primaryServer': 'stun.cloudflare.com', 'primaryPort': 3478},
});

// Unset arguments now come from the configuration.
final handler = await StunShspHandler.createDefault();
final detector = NATDetectorShsp(socket: handler);
```

| Key | Default | Used by |
|---|---|---|
| `socket.ipv6` | `true` | `StunShspHandler.createDefault` |
| `socket.port` | `0` | `StunShspHandler.createDefault` |
| `socket.ipv4Port` | `0` | `DualStunShspHandler.createDefault` |
| `socket.ipv6Port` | `0` | `DualStunShspHandler.createDefault` |
| `nat.primaryServer` | `stun.l.google.com` | `NATDetectorShsp` |
| `nat.primaryPort` | `19302` | `NATDetectorShsp` |
| `nat.timeoutSeconds` | `5.0` | `NATDetectorShsp` |

`initStunShspConfig` deep-merges its argument onto the defaults and accepts either the bare section or a larger document nesting it under `stunShspConfigKey`, so a multi-domain JSON blob can be handed over as-is. To read the values from your own class, mix `StunShspConfigExtension` on top of `ConfigExtension`; in static contexts use the top-level helpers (`defaultStunShspIpv6Enabled()`, `defaultStunShspNatTimeout()`, `stunShspConfigValue([...])`, ...).

### NAT compatibility

```dart
final detector = NATDetectorShsp(socket: handler);
final result = await detector.natShspCompatibility();

print('${result.natType.displayName} — SHSP usable: ${result.isNatShspsCompatible}');
```

Symmetric NAT, symmetric firewall and blocked UDP report `isNatShspsCompatible: false`; open internet and the cone types report `true`.

## API

### `IStunShspHandler` / `StunShspHandler`

Both an `IStunHandler` and an `IShspSocketMigratable`, so it can be passed to either package.

| Member | Description |
|---|---|
| `StunShspHandler(socket, {address, port, timeout, onLog})` | Wraps an `IShspSocketMigratable`; STUN arguments fall back to the `stun` configuration |
| `createDefault({ipv6, port, compressionCodec, address, stunPort, timeout})` | Binds a socket of its own; unset values come from the configuration |
| `stunHandler` / `shspSocket` | The two halves |
| `performStunRequest()` / `performLocalRequest()` / `pingStunServer()` | STUN, delegated |
| `setStunServer(address, port)` | STUN server for this handler |
| `getSocket()` / `getIpVersion()` | The socket STUN uses, and its family |
| `migrateSocket(socket)` | Swap the socket under both halves |
| `close()` / `destroy()` | Close the STUN half and the socket |

Plus the whole `IShspSocket` surface (`sendTo`, `setMessageCallback`, `extractProfile`, `localPort`, `compressionCodec`, the `RawDatagramSocket` members, ...) via `ShspSocketMigratableDelegationMixin`.

### `IDualStunShspHandler` / `DualStunShspHandler`

| Member | Description |
|---|---|
| `DualStunShspHandler({ipv4Migratable, ipv6Migratable})` | The DI constructor |
| `DualStunShspHandler.fromSockets(sockets)` | Wraps plain sockets into migratable ones |
| `createDefault({ipv4Port, ipv6Port, compressionCodec})` | Binds IPv4, and IPv6 when the host has it |
| `dualStunHandler` | The `IDualStunHandler` over both families |
| `getStunShspHandler([type])`, `ipv4StunShspHandler`, `ipv6StunShspHandler` | Per-family combined handlers (nullable) |
| `getSocket([type])`, `getSocketMigratable([type])` | The SHSP sockets |
| `migrateSocket(socket, [type])`, `migrateSocketIpv4/6`, `refreshSocket([type])`, `refreshSockets()` | Socket swaps; each rebuilds that family's handler |
| `close({type})` / `destroy()` | Close one family or everything |

### Registry wiring

| Function | Description |
|---|---|
| `initializeStunShsp({key})` | SHSP graph, then STUN graph, then this package's singletons, under `key` |
| `StunShspInjector` | Host of the three graphs (`MainInjectionStunMixin` + `MainInjectionStunShspMixin`); its before hooks run `DualShspInjector` and `registerAllSingletonsStun` |
| `connectStunShspHandlerSubkeys({key})` | Connects `StunShspHandler` under the `ipv4`/`ipv6` subkeys |
| `MainInjectionStunShsp` (generated) | `lib/main_injection.dart`, regenerated by `melos run registry` |

### Registry-level migration

| Function | Description |
|---|---|
| `migrateStunShspSocket(socket, {key})` | Migrates the slot matching `socket`'s family; returns the (unchanged) combined handler |
| `migrateStunShspSocketIpv4({key})` / `...Ipv6({key})` | Binds a fresh socket of that family and migrates it |
| `migrateDualStunShspSockets({ipv4Socket, ipv6Socket, key})` | Both families in one call; each socket must match the family it's passed as |
| `migrateStunHandlerEntry(socket, {key})` | Refreshes only the plain `IStunHandler` entry, after a hand-made swap |

## Dependencies

| Package | Role |
|---|---|
| [`stun`](https://pub.dev/packages/stun) | STUN protocol, NAT detection |
| [`shsp`](https://pub.dev/packages/shsp) | Structured UDP socket with optional compression |
| [`singleton_manager`](https://pub.dev/packages/singleton_manager) | Registry, DI annotations and generator |
| [`config_manager`](https://pub.dev/packages/config_manager) | Sectored configuration |

## License

MIT
