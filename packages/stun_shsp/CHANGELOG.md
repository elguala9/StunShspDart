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
