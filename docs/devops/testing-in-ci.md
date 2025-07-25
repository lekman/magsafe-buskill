# Testing in CI/CD Environments

## Authentication Service Tests

The `AuthenticationService` uses Apple's LocalAuthentication framework, which has specific behaviors in different environments:

### Local Development (Real Device)

- Full biometric authentication available (TouchID/FaceID)
- Password fallback works as expected
- All authentication policies function normally

### Local Development (Simulator)

- No biometric hardware available
- Authentication attempts fail with `.biometryNotAvailable`
- Password fallback may work depending on simulator configuration

### CI Environment (GitHub Actions)

- Runs on `macos-latest` runners
- No biometric hardware available
- Authentication tests are designed to handle these limitations gracefully

## Test Behavior in CI

### Expected Outcomes

1. **Biometric Availability Tests**

   - `isBiometricAuthenticationAvailable()` returns `false`
   - `biometryType` returns `.none`
   - Tests pass by expecting and handling these conditions

2. **Authentication Flow Tests**

   - Authentication attempts fail with appropriate errors
   - Tests accept failure as valid outcome in CI
   - Debug logging helps identify CI-specific behavior

3. **Error Handling Tests**
   - All error types are tested for proper descriptions
   - No actual authentication required
   - Always passes in CI

### CI-Specific Test Features

```swift
// Tests log CI-specific information
print("[CI Test] Biometric authentication is NOT available (expected in CI)")

// Tests handle multiple valid outcomes
switch result {
case .failure(let error):
    // Expected in CI - biometrics not available
case .cancelled:
    // Also acceptable
case .success:
    // Unlikely but not impossible
}
```

### Test Strategy

1. **Graceful Degradation**

   - Tests don't fail when biometrics are unavailable
   - Multiple acceptable outcomes for each test
   - Clear logging for debugging CI issues

2. **No Mocking Required**

   - Tests work with real `LAContext`
   - Handle actual system responses
   - No complex mocking setup needed

3. **Coverage Focus**
   - Test error handling paths
   - Validate service configuration
   - Ensure graceful failure modes

## Running Tests Locally

To simulate CI behavior locally:

```bash
# Run tests with CI environment variable
CI=true swift test

# Run specific tests with CI flag
CI=true swift test --filter AuthenticationServiceTests

# Run without CI flag for full testing
swift test --filter AuthenticationServiceTests -v
```

## CI Test Adaptations

The authentication tests detect CI environments using the `CI` environment variable:

```swift
var isRunningInCI: Bool {
    return ProcessInfo.processInfo.environment["CI"] != nil ||
           ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] != nil
}
```

In CI mode, tests:

- Skip complex authentication flows that may hang
- Test basic functionality instead
- Verify that services don't crash
- Focus on testable components

## Future Improvements

1. **Dependency Injection**

   - Create protocol for authentication
   - Inject mock implementation for tests
   - Better unit test isolation

2. **UI Tests**

   - Test actual authentication flow
   - Require real device
   - Separate test target

3. **Integration Tests**
   - Test with other services
   - Validate complete workflows
   - End-to-end scenarios
