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
