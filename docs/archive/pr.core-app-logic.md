## Summary

This PR implements the core application logic for MagSafe Guard, introducing the central `AppController` class that coordinates all services and manages application state. Additionally, it enhances our GitHub Actions security posture and adds Software Bill of Materials (SBOM) support for supply chain transparency.

## Type of Change

- [x] ✨ New feature (non-breaking change which adds functionality)
- [x] 🔒 Security fix
- [x] 🔧 Configuration change
- [x] ♻️ Code refactoring

## Related Issue

- Implements Task 6: Core Application Logic (from Task Master)
- Addresses GitHub security alerts for workflow token permissions
- Implements SBOM generation for security compliance

## Changes

### Core Application Logic

- **AppController**: New central coordinator class that manages:
  - Application state machine (disarmed → armed → grace period → triggered)
  - Service integration (PowerMonitor, Authentication, SecurityActions, Notifications)
  - Grace period timer with configurable duration (default 10 seconds)
  - Event logging system for audit trail
  - Menu bar integration helpers

- **NotificationService**: New unified notification system with:
  - Multiple delivery methods (UserNotifications API and Alert fallback)
  - Test environment support
  - Critical alert handling for security events

- **AppDelegateCore Refactoring**:
  - Integrated with AppController while maintaining backward compatibility
  - Simplified state management through delegation
  - Improved separation of concerns

### Security Enhancements

- **GitHub Actions Security**:
  - Pinned all GitHub Actions to commit SHAs (prevents supply chain attacks)
  - Added explicit permission declarations to all workflows
  - Created dedicated CodeQL workflow for better SAST detection
  - Set up Dependabot for automated security updates

- **SBOM Support**:
  - Added SPDX format SBOM generation
  - Integrated into pre-push hooks
  - Provides supply chain transparency

### Infrastructure Improvements

- Created reusable composite action for Swift builds
- Enhanced test coverage with new integration tests
- Improved CI/CD caching strategies

## Screenshots (if applicable)

N/A - Backend changes only

## Testing

### How Has This Been Tested?

- [x] Unit tests
- [x] Integration tests
- [x] Manual testing
- [x] Tested on physical device

### Test Configuration

- macOS Version: 14.0+ (Big Sur and above)
- Hardware: MacBook Pro M1/M2
- Power Adapter Type: USB-C, MagSafe 3

### Test Coverage

- AppController: 100% coverage with 10 unit tests
- NotificationService: Full coverage including test environment handling
- Integration tests: Authentication flow, state transitions, event logging

## Security Considerations

- [x] No secrets or sensitive data exposed
- [x] Authentication flows tested
- [x] Permissions are appropriately scoped
- [x] Security scanning passed (check workflow results)

### Additional Security Notes

- All GitHub Actions now use immutable SHA references
- Workflows follow principle of least privilege for tokens
- SBOM provides transparency for security audits
- Notification service properly handles test environments to prevent crashes

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

### Architecture Decisions

1. **AppController as Central Coordinator**: Follows the coordinator pattern to manage complex state and service interactions
2. **Event-Driven Design**: Uses callbacks and notifications for loose coupling
3. **Thread-Safe Event Logging**: Uses dispatch queues for concurrent access
4. **Graceful Degradation**: Falls back to alert windows when UserNotifications unavailable

### Breaking Changes

None - All changes maintain backward compatibility

### Performance Considerations

- Grace period timer uses efficient Timer API
- Event log automatically pruned at 1000 entries
- Notification permissions requested lazily on first use

## Post-Merge Tasks

- [x] Update CHANGELOG.md (using release-please)
- [ ] Notify team of breaking changes (N/A - no breaking changes)
- [ ] Update deployment documentation
- [x] Archive PR document to docs/archive

---

## Reviewer Notes

Please pay special attention to:

1. **Security**: Verify authentication flows and state transitions
2. **Thread Safety**: Event logging and state management
3. **Error Handling**: Grace period cancellation and service failures
4. **Test Coverage**: All new code has corresponding tests
