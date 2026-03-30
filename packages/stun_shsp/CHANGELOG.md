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
