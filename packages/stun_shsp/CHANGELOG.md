## 0.4.0

### Changed — breaking

Ported the package to the current `shsp`, `stun` and `singleton_manager` 2.x APIs, adopting the same architecture as those packages (config sector, `@dependencyInjectable` classes with generated factories, a generated `main_injection.dart`, registry wiring helpers).

- The socket "wrapper" is gone, following `shsp`: `IShspSocketWrapper`/`ShspSocketWrapper` become `IShspSocketMigratable`/`ShspSocketMigratable`, and `ShspSocketWrapperDelegationMixin` becomes `ShspSocketMigratableDelegationMixin`. `IStunShspHandler.shspSocket` is now an `IShspSocketMigratable`.
- Dual-stack selection is by `InternetAddressType` instead of a `bool ipv6`, following `stun`: `close({type})`, `setStunServer(address, port, {type})`, `getHandler/setHandler/clearHandler/replaceHandler({type})`, `getLastStunUpdated({type})`, `migrateSocket(socket, [type])`, `getSocket([type])`.
- `DualStunShspHandler` now extends `DualShspSocketAuto` and implements `IDualShspSocketAuto` only. It is no longer an `IDualStunHandler`, because `IDualStunHandler.getSocket({type})` and `IDualShspSocket.getSocket([type])` cannot both be satisfied by one member; the dual STUN handler is exposed as `dualStunHandler`, and the rest of its surface is forwarded by the new `DualStunHandlerDelegationMixin`. Its per-family handlers are `ipv4StunShspHandler`/`ipv6StunShspHandler`/`getStunShspHandler([type])` and are nullable, since a host without IPv6 binds one socket only.
- `initializePointStunShsp()` and `initializePointRegistryStunShsp(key)` are replaced by `initializeStunShsp({key})`, `StunShspInjector` and `connectStunShspHandlerSubkeys({key})`, on `RegistryManager.instance` instead of `SingletonDIAccess`/`RegistryAccess`. Everything is keyed, so the two entry points collapse into one. `StunShspInjector` wires all three graphs from its before hooks — `DualShspInjector` (which binds the ipv4/ipv6 `RawDatagramSocket`s) and then `registerAllSingletonsStun` — so the STUN graph of the `stun` package resolves onto the very same sockets as the SHSP one. `DualStunInjector` is deliberately not used: it would bind sockets of its own and overwrite those connections.
- `lib/generated/stun_shsp_handler_di.dart` is replaced by the generated `lib/main_injection.dart` (`MainInjectionStunShspMixin.registerAllSingletonsStunShsp`). Both handlers are now `@dependencyInjectable` and carry a generated `dependencyInjectionFactory`.
- The mixins are renamed after the `shsp` convention: `IStunHandlerDelegationMixin` → `StunHandlerDelegationMixin`, `IDualStunHandlerDelegationMixin` → `DualStunHandlerDelegationMixin`. They no longer forward the members that the new STUN API dropped (`addOnSocketRefresh`/`removeOnSocketRefresh`, `initializeDI`, `setIpv4Handler`/`clearIpv4Handler`, `ipv4LastStunUpdated` and friends) and now forward `getIpVersion()`.
- Neither interface implements `IValueForRegistry` any more — it no longer exists in `singleton_manager` 2.x.
- Sources moved to `lib/src/implementations/` (was the misspelled `imlementations/`), with `lib/src/nat/` and `lib/src/registry/` next to it, mirroring the `stun` package layout.

### Added

- `config_manager`-based configuration, following the same architecture as the `stun` and `shsp` packages, but *reading their sectors* instead of duplicating them: the `stun_shsp` sector owns only the bind ports (`stunShspConfig.socket.port`/`ipv4Port`/`ipv6Port`), while the address family comes from `ipVersion` of the `stun` sector, the STUN server and the `nat` section from that same sector, and keep-alive/handshake/retry from the `shsp` one — so configuring `stun`/`shsp` configures this package too and no value exists twice. Ships `defaultStunShspConfig`, `initStunShspConfig()` / `ensureStunShspConfig()`, `unwrapStunShspConfig()` / `mergeStunShspConfig()`, the `StunShspConfigExtension` mixin (typed getters for the ports *and* for the borrowed values: `defaultIpv6Enabled`, `defaultNatPrimaryServer/Port/Timeout`, `defaultStunServerAddress/Port`, `defaultStunTimeout`, `defaultKeepAliveSeconds`) and static-context helpers (`defaultStunShspIpv6Enabled()`, `defaultStunShspPort()`, `defaultStunShspIpv4Port()`, `defaultStunShspIpv6Port()`, `defaultStunShspNatPrimaryServer()`, `defaultStunShspNatPrimaryPort()`, `defaultStunShspNatTimeout()`, `stunShspConfigValue()`). `initStunShspConfig()` remains the single entry point: it loads the ports and forwards `socket.ipv6` → `stun.ipVersion`, `nat` → the `stun` sector and a `shsp` section → the `shsp` sector, deep-merging so a configuration loaded earlier keeps what the call doesn't mention; with no arguments it resets every sector it reads. `stunShspConfigValue()` reads this sector only — use `stunConfigValue()` for the `nat`/`server` sections.
- Test coverage for the configuration defaults, the deep-merge of overrides, the nested-document form, and the static-context helpers (`stun_shsp_config_test.dart`), for the registry wiring (`stun_shsp_registry_wiring_test.dart`) and for the dual handler (`dual_stun_shsp_handler_test.dart`).
- `StunShspHandler(socket, {address, port, timeout, onLog})` takes the STUN server and timeout, so a handler no longer has to be built against the configured server and then reconfigured.
- `DualStunShspHandler.fromSockets(Sockets)`, which wraps plain sockets into migratable ones.
- Registry-level socket migration, the counterpart of `migrateShspSocket`/`migrateStunHandlerSocket` in the `shsp` and `stun` packages and delegating to both: `migrateStunShspSocket(socket, {key})`, `migrateStunShspSocketIpv4({key})` / `migrateStunShspSocketIpv6({key})`, `migrateDualStunShspSockets({ipv4Socket, ipv6Socket, key})` and `migrateStunHandlerEntry(socket, {key})`. The handlers and the migratable wrapper are never replaced — only the `RawDatagramSocket`/`IShspSocket` entries and the plain `IStunHandler` of the STUN graph move — so `IStunShspHandler`, `IDualStunShspHandler` and every peer holding them keep working across a swap. Covered by `stun_shsp_socket_migration_test.dart`.
- Examples for the configuration (`config_example.dart`), the registry wiring (`registry_example.dart`) and the socket migration (`socket_migration_example.dart`); the other examples were rewritten against the new API.

### Changed

- `StunShspHandler.createDefault()` (`ipv6`, `port`), `DualStunShspHandler.createDefault()` (`ipv4Port`, `ipv6Port`) and `NATDetectorShsp` (`primaryServer`, `primaryPort`, `timeout`) take those parameters as optional and fall back to the configuration instead of hardcoded values. `NATDetectorShsp.primaryServer` and `primaryPort` are no longer required.
- `DualStunShspHandler.createDefault()` binds IPv6 best-effort instead of failing on hosts without it.
- The STUN handler is built on the migratable socket rather than on the socket behind it, so a `migrateSocket` moves both halves at once and `getSocket()` reports the new port.

## 0.3.0

### Added

- `performStunRequest({bool ipv6 = true})` now supports per-IP-family discovery. IPv6 is targeted by default, with graceful fallback to IPv4 when no IPv6 socket is available. Pass `ipv6: false` to force IPv4.
- STUN responses are now cached independently per IP family (`_cachedIpv4StunResponse`, `_cachedIpv6StunResponse`).
- IPv6 STUN test suite (`stun_shsp_handler_ipv6_test.dart`); IPv6-only cases skip automatically when the host has no IPv6 connectivity.

### Changed

- `setStunServer()` now invalidates both the IPv4 and IPv6 cached responses so the next request uses the new server.

## 0.2.2

### Fixed

- `initializePointStunShsp()` now registers `IShspSocket` as an autonomous type in the DI container (`initialize_point.dart:14`). Previously, consumers resolving `SingletonDIAccess.get<IShspSocket>()` would fail because only `DualShspSocketWrapperDI.ipv4Socket` was accessible through the wrapper.

### Added

- Comprehensive test coverage for all 8 public DI registrations after `initializePointStunShsp()`, including identity checks across the object graph (`IShspSocket`, `IDualStunHandler`, `IDualCallbackHandler`, `DualShspSocketWrapperDI`, `StunHandlerBaseDI`, etc.)
- Consolidated integration test suite (socket migration, STUN requests) into the `stun_shsp` package.

## 0.2.1

### Changed

- Bumped `shsp` to `^1.8.0`

## 0.2.0

### Changed

- **Major refactor**: STUN requests now run **on the same SHSP socket** instead of separate raw sockets. This guarantees that the public port discovered by STUN matches exactly the port that P2P peers must use to reach this node — eliminating port mismatch bugs.
- Bumped `stun` to `^1.5.1`
- Bumped `shsp` to `^1.8.0`
- Updated SDK constraint to `>=3.5.0 <4.0.0`

### Added

- Comprehensive test suite in `stun_shsp_handler_port_test.dart` covering:
  - STUN/SHSP port matching (core regression test)
  - IPv4 and IPv6 socket sanity checks
  - Explicit port binding and OS-assigned ports
  - Double-initialize guard
  - Dual socket structure validation
  
### Fixed

- STUN discoveries now reflect the exact SHSP socket port used for P2P communication

## 0.1.4

### Fixed

- Fixed `LateInitializationError` in `StunShspHandler.initialize()`: now correctly creates `StunHandlerSingleton` instance before attempting initialization. The manual initialization path (non-DI) was attempting to access `_stunHandler` before assignment, violating Dart's late variable contract.

## 0.1.3

### Changed

- Prepared for pub.dev publication

## 0.1.2

### Changed

- Bumped `stun` to `^1.4.2`
- Bumped `shsp` to `^1.6.1`
- Bumped `singleton_manager` to `^0.6.1`
- Removed deprecated lint rules (`avoid_returning_null_for_future`, `invariant_booleans`, `iterable_contains_unrelated_type`, `list_remove_unrelated_type`) from `analysis_options.yaml`

## 0.1.0

### Added

- `IStunShspHandler` interface combining STUN NAT traversal and SHSP socket operations
- `StunShspHandler` concrete implementation with dual IPv4/IPv6 support
- `StunShspHandlerSingleton` — Dart singleton wrapper around `StunShspHandler`
- `StunShspHandlerDI` — auto-generated dependency injection class via `singleton_manager_generator`
- `initializePointStunShsp()` — one-call bootstrap that wires SHSP sockets, STUN handlers, and DI registration
- Socket migration at runtime via `migrateSocketIpv4()` and `migrateSocketIpv6()`
- Graceful IPv6 fallback: IPv6 socket is created when available, skipped silently otherwise
- Optional compression codec support via `ICompressionCodec` passed to `ShspSocket`
- Public API: `performStunRequest()`, `performLocalRequest()`, `pingStunServer()`, `setStunServer()`, `close()`
- `isInitialized` getter on `IStunShspHandler` / `StunShspHandler`

### Fixed

- `initialize()` now throws `StateError` if called after `injectDependencies()`, preventing silent
  overwrite of DI-injected dependencies
