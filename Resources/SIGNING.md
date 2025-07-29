# MagSafe Guard Code Signing Resources

This directory contains the code signing and entitlements configuration for MagSafe Guard.

## Files

### Entitlements Files

- **`MagSafeGuard.entitlements`** - App Store distribution entitlements (sandbox enabled)
- **`MagSafeGuard.developerid.entitlements`** - Developer ID distribution (sandbox disabled)
- **`MagSafeGuard.development.entitlements`** - Development/testing (relaxed restrictions)
- **`MagSafeGuard.ci.entitlements`** - CI/automated testing (minimal entitlements)

### Configuration

- **`SigningConfig.xcconfig`** - Centralized Xcode configuration (for future Xcode integration)
- **`Info.plist`** - App bundle information and usage descriptions

## Quick Reference

### Sign for Different Scenarios

```bash
# Development (local testing)
task swift:sign:dev

# Release (Developer ID for direct distribution)
task swift:sign:release

# App Store submission
task swift:sign:appstore

# CI/automated testing (no certificate required)
task swift:sign:ci

# Interactive mode (prompts for choice)
task swift:sign
```

### Verify Signing

```bash
# Comprehensive verification
task swift:sign:verify
```

### Export Certificate for CI

```bash
# Export your certificate for CI/CD
task swift:sign:export-cert
```

## Key Capabilities Required

1. **Menu Bar App**: `LSUIElement = true` in Info.plist
2. **CloudKit**: iCloud container and services
3. **Security**: Camera, location, Apple Events
4. **Authentication**: Touch ID (runtime check)
5. **Power Monitoring**: IOKit (no special entitlement)
6. **Keychain**: Automatic with app signature

## Signing Script

The main signing logic is in `/scripts/sign-app.sh`. It handles:
- Certificate detection
- Entitlements selection
- Code signing
- Verification
- Notarization readiness

## For More Information

See the comprehensive guide at `/docs/maintainers/code-signing.md`