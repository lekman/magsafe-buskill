## Summary

This PR introduces a flexible feature flag system for MagSafe Guard, allowing runtime configuration of features through a JSON file. The system enables easy toggling of features without code changes, making debugging and deployment configuration much simpler.

## Type of Change

- [x] ✨ New feature (non-breaking change which adds functionality)
- [x] 🔧 Configuration change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] ♻️ Code refactoring
- [ ] 🔒 Security fix
- [ ] ⬆️ Dependency update

## Related Issue

Addresses the need for better feature control as identified in the analysis of the location-tracking branch issues.

## Changes

- Added `FeatureFlags.swift` with JSON file support for configuration
- Changed default behavior: all features are now enabled by default (safer approach)
- Added support for `feature-flags.json` configuration file with multiple search locations
- Environment variables can override JSON configuration (highest priority)
- Created `feature-flags.example.json` as a template for users
- Added comprehensive documentation in `docs/FEATURE-FLAGS.md`
- Updated `.gitignore` to exclude `feature-flags.json` while keeping the example file
- Brought over updated `.gitignore` from feature/location-tracking branch

## Key Features of the Feature Flag System

### Configuration Priority (highest to lowest)

1. Environment variables (e.g., `FEATURE_POWER_MONITORING=false`)
2. JSON configuration file (`feature-flags.json`)
3. Default values (all enabled)

### Search Locations for JSON file

1. Current working directory
2. Application bundle resources
3. User's home directory
4. Application Support directory

### Available Flags

- **Core Features**: power monitoring, accessibility, notifications, authentication, auto-arm
- **Optional Features**: location, network monitor, security evidence, cloud sync
- **Telemetry**: Sentry integration, performance metrics
- **Debug Options**: verbose logging, mock services, sandbox disable

## Screenshots (if applicable)

N/A - This is a backend feature with no UI changes.

## Testing

### How Has This Been Tested?

- [x] Unit tests
- [ ] Integration tests
- [x] Manual testing
- [ ] Tested on physical device

Created and ran a test script that verified:

- JSON file parsing works correctly
- Environment variable overrides function as expected
- Feature flag checks return correct values

### Test Configuration

- macOS Version: Sonoma 14.x
- Hardware: Apple Silicon Mac
- Power Adapter Type: N/A (feature flags don't interact with hardware)

## Security Considerations

- [x] No secrets or sensitive data exposed
- [x] Authentication flows tested - N/A (no auth in feature flags)
- [x] Permissions are appropriately scoped - N/A
- [x] Security scanning passed (check workflow results)

The feature flag system itself doesn't introduce security risks. Configuration files should not contain sensitive data.

## Checklist

- [x] My code follows the style guidelines of this project
- [x] I have performed a self-review of my own code
- [x] I have commented my code, particularly in hard-to-understand areas
- [x] I have made corresponding changes to the documentation
- [x] My changes generate no new warnings
- [x] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [x] Any dependent changes have been merged and published

## Additional Notes

This feature flag system is designed to help debug and resolve issues found in the location-tracking branch by allowing selective enabling/disabling of features. The JSON-based configuration makes it easy to:

1. Test different feature combinations
2. Disable problematic features without recompiling
3. Have different configurations for development vs. production
4. Share configurations between team members

The decision to enable all features by default (change from the original implementation) ensures the app works out-of-the-box without requiring configuration.

## Post-Merge Tasks

- [ ] Update CHANGELOG.md (if not using release-please)
- [ ] Notify team of breaking changes - N/A
- [ ] Update deployment documentation
- [x] Other: Consider creating preset configurations (minimal, development, production)

---

## Usage Example

1. Copy the example configuration:

   ```bash
   cp feature-flags.example.json feature-flags.json
   ```

2. Edit `feature-flags.json` to disable specific features:

   ```json
   {
     "FEATURE_LOCATION": false,
     "SENTRY_ENABLED": false
   }
   ```

3. Run the app - it will automatically load the configuration.

For more details, see `docs/FEATURE-FLAGS.md`.
