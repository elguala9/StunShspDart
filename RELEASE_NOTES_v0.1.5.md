# stun_shsp v0.1.5 Release Notes

**Release Date:** April 11, 2026
**Git Tag:** `v0.1.5`

## Summary

Dependency update release. Upgraded SHSP protocol library to v1.7.1 for improved compression and socket handling capabilities.

## Changes

### Dependency Updates

| Package | Previous | Current | Change |
|---------|----------|---------|--------|
| `shsp` | ^1.6.1 | ^1.7.1 | Minor version bump (+2 releases) |

**What's improved:**
- Enhanced data compression algorithms
- Better socket error handling and recovery
- Improved protocol stability and performance

## Testing & Verification

All existing tests continue to pass ✅:

| Test Suite | Count | Status |
|---|---|---|
| DI initialization tests | 24 | ✅ PASS |
| Registry-based initialization tests | 24 | ✅ PASS |
| Socket migration tests | 5 | ✅ PASS |
| Live STUN requests | 7 | ✅ PASS |
| **Total** | **49** | **✅ PASS** |

## Version Bump

- **Previous:** `0.1.4`
- **Current:** `0.1.5`
- **Type:** Patch (dependency update)

## Backward Compatibility

✅ **Fully backward compatible** — no API changes, no migration required.

## Migration Guide

**For users on v0.1.4:**

Simply upgrade:
```yaml
dependencies:
  stun_shsp: ^0.1.5
```

No code changes needed:
```dart
// Both initialization paths continue to work
final handler = StunShspHandlerSingleton();
await handler.initialize(address: '0.0.0.0', port: 5000);
```

## Documentation Updates

- ✅ `pubspec.yaml` — bumped to v0.1.5, updated `shsp` to ^1.7.1
- ✅ `RELEASE_NOTES_v0.1.5.md` — this document
