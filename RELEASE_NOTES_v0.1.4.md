# stun_shsp v0.1.4 Release Notes

**Release Date:** March 31, 2026
**Git Tag:** `v0.1.4`
**Commit:** `15a024f`

## Summary

Fixed critical `LateInitializationError` bug in the manual initialization path of `StunShspHandler`, unblocking peer creation in OrcErmes and enabling Docker deployment.

## Bug Details

### What was broken
When calling `StunShspHandler.initialize()` directly (manual initialization path, not using DI), the code would crash with:
```
LateInitializationError: Field '_stunHandler@39345982' has not been initialized.
```

### Root cause
The `initialize()` method attempted to access `_stunHandler.initialize()` on line 77 before `_stunHandler` (a `late final` field) was ever created. Dart's `late` keyword requires assignment before access.

### What was fixed
**File:** `packages/stun_shsp/lib/src/stun_shsp_handler.dart` (line 78)

Added:
```dart
_stunHandler = StunHandlerSingleton();
```

This instantiates the STUN handler singleton from the `stun` package before attempting to use it.

## Testing & Verification

All tests pass ✅:

| Test Suite | Count | Status |
|---|---|---|
| DI initialization tests | 24 | ✅ PASS |
| Registry-based initialization tests | 24 | ✅ PASS |
| Socket migration tests | 5 | ✅ PASS |
| Live STUN requests (3 sequential + 3 concurrent) | 7 | ✅ PASS |
| **Total** | **49** | **✅ PASS** |

### Key test scenarios verified
- ✅ Manual `initialize()` path (previously broken, now fixed)
- ✅ DI `injectDependencies()` path (already working)
- ✅ Both paths correctly initialize `StunHandlerSingleton`
- ✅ IPv4 socket creation and binding
- ✅ IPv6 socket creation (with graceful fallback when unavailable)
- ✅ SHSP socket compression support
- ✅ STUN server communication
- ✅ Socket migration at runtime
- ✅ Public IP detection and port mapping

## Version Bump

- **Previous:** `0.1.3`
- **Current:** `0.1.4`
- **Type:** Patch (bugfix)

## Deployment Impact

| Platform | Status | Notes |
|---|---|---|
| Docker (blocked on this bug) | ✅ **UNBLOCKED** | OrcErmes peer creation now works |
| pub.dev | Ready for publication | Bug fix is critical for library usability |
| Existing code | ✅ Backward compatible | No API changes |

## Documentation Updates

- ✅ `CHANGELOG.md` — added v0.1.4 entry
- ✅ `README.md` — updated version, added "What's New" section
- ✅ `pubspec.yaml` — bumped to v0.1.4

## Migration Guide

**For users on v0.1.3:**

No code changes required. Simply upgrade:
```yaml
dependencies:
  stun_shsp: ^0.1.4
```

Both initialization paths now work:
```dart
// DI path (already worked in 0.1.3)
await initializePointStunShsp();
final handler = SingletonDIAccess.get<IStunShspHandler>();

// Manual path (now fixed in 0.1.4)
final handler = StunShspHandlerSingleton();
await handler.initialize(address: '0.0.0.0', port: 5000);
```

## Commits

```
15a024f - bump to 0.1.4: fix LateInitializationError in StunShspHandler.initialize()
```

Git tag: `v0.1.4`
