## Summary

This PR adds comprehensive code signing infrastructure from the location-tracking branch and improves the build tooling to make it more generic and reusable. The main focus is establishing a robust signing pipeline for macOS development while fixing critical issues with menu bar visibility.

## Type of Change

- [x] ✨ New feature (non-breaking change which adds functionality)
- [x] 🐛 Bug fix (non-breaking change which fixes an issue)
- [x] 🔧 Configuration change
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] ♻️ Code refactoring
- [ ] 🔒 Security fix
- [ ] ⬆️ Dependency update

## Related Issue

Feature branch for implementing code signing infrastructure

## Changes

### Code Signing Infrastructure

- Added comprehensive signing workflow (`build-sign.yml`) with support for development, CI, and release signing
- Created multiple entitlements files for different signing contexts (development, CI, Developer ID)
- Implemented `sign-app.sh` script with automatic identity detection and verification
- Added signing configuration via `SigningConfig.xcconfig` for Xcode integration
- Created detailed signing documentation (`SIGNING.md`, `code-signing.md`, `code-signing-implementation.md`)

### Build Tooling Improvements

- **Fixed menu bar icon visibility** by adding `CFBundleIdentifier` to Info.plist during build process
- Made `tasks/swift.yml` completely generic using dynamic variables - can now be reused in other Swift projects
- Added signature verification output to the `run` task for immediate feedback
- Removed deprecated `pre-push` and `pre-pr` tasks from Taskfile

### Task Infrastructure

- Added comprehensive Git workflow tasks (`git.yml`) with smart commit/PR workflows
- Enhanced YAML validation and management tasks (`yaml.yml`)
- Improved SonarCloud integration with better coverage handling
- Added extensive documentation for all task files

### Key Files Added/Modified

- `Bundler.toml` - Swift Bundler configuration for building macOS apps
- `Resources/MagSafeGuard.*.entitlements` - Entitlements for different signing contexts
- `scripts/sign-app.sh` - Automated signing script with identity detection
- `tasks/*.yml` - Enhanced task files with better documentation and functionality

## Screenshots (if applicable)

N/A - Infrastructure and tooling changes

## Testing

### How Has This Been Tested?

- [x] Unit tests
- [ ] Integration tests
- [x] Manual testing
- [x] Tested on physical device

### Test Configuration

- macOS Version: 15.5 (Sonoma)
- Hardware: MacBook Pro
- Power Adapter Type: USB-C

### Testing Results

- ✅ Successfully built and signed app with development certificate
- ✅ Menu bar icon now displays correctly after Info.plist fixes
- ✅ Signature verification shows proper identity and team ID
- ✅ Swift tasks work generically without hardcoded project names
- ✅ App launches successfully via Launch Services

## Security Considerations

- [x] No secrets or sensitive data exposed
- [x] Authentication flows tested
- [x] Permissions are appropriately scoped
- [x] Security scanning passed (check workflow results)

### Security Notes

- All signing identities are resolved at runtime - no hardcoded certificates
- Entitlements properly scoped for each environment (development has relaxed sandbox)
- Signing script validates certificates before use
- No sensitive keys or certificates are committed to the repository

## Checklist

- [x] My code follows the style guidelines of this project
- [x] I have performed a self-review of my own code
- [x] I have commented my code, particularly in hard-to-understand areas
- [x] I have made corresponding changes to the documentation
- [x] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [x] New and existing unit tests pass locally with my changes
- [x] Any dependent changes have been merged and published

## Additional Notes

### Why These Changes?

1. **Code Signing Infrastructure**: Essential for distributing macOS apps outside of development. The location-tracking branch had a mature signing setup that was tested and working.

2. **Menu Bar Fix**: Swift Bundler wasn't including `CFBundleIdentifier` in Info.plist, causing the menu bar icon to not appear. This is now fixed automatically during the build process.

3. **Generic Tasks**: The swift.yml task file was hardcoded with "MagSafeGuard" references. Now it dynamically detects the package name from Package.swift, making it reusable.

### Migration from location-tracking

This brings over the proven signing infrastructure from the location-tracking branch, which includes:

- Multi-environment signing support (dev, CI, release)
- Automatic certificate detection
- Comprehensive documentation
- GitHub Actions workflow for automated builds

The signing infrastructure has been tested extensively and provides a solid foundation for app distribution.

## Post-Merge Tasks

- [ ] Update CHANGELOG.md (if not using release-please)
- [ ] Notify team of breaking changes
- [ ] Update deployment documentation
- [ ] Other: Test signing workflow in CI environment

---

<!--
Reviewer Guidelines:
1. Check security implications for all changes
2. Verify no kernel extensions or privileged operations added
3. Ensure TouchID/password requirements are maintained
4. Confirm all authentication paths are secure
-->
