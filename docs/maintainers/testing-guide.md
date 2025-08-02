# Testing Guide

This guide explains the testing strategy for MagSafe Guard, focusing on achieving high code coverage through proper separation of business logic from system interfaces.

## Testing Philosophy

### Core Principles

1. **Separation of Concerns**: Extract business logic from UI and system interfaces
2. **Protocol-Based Testing**: Use protocols to abstract system dependencies
3. **Mock Everything External**: Mock all external dependencies for unit tests
4. **Manual Acceptance Testing**: Cover system integration through manual tests

### Testing Layers

```text
┌─────────────────────────────────┐
│   Manual Acceptance Tests       │ ← Real system integration
├─────────────────────────────────┤
│   Unit Tests with Mocks         │ ← Business logic (100% coverage target)
├─────────────────────────────────┤
│   Protocol Abstractions         │ ← Interfaces for system dependencies
├─────────────────────────────────┤
│   Business Logic               │ ← Pure, testable code
├─────────────────────────────────┤
│   System Integration Code      │ ← Thin layer, minimal logic
└─────────────────────────────────┘
```

## Architecture Patterns

### Protocol-Based Dependency Injection

#### Example: Security Actions

```swift
// Protocol defining system actions
protocol SystemActionsProtocol {
    func lockScreen() throws
    func playAlarm(volume: Float) throws
    func stopAlarm()
    // ... other system actions
}

// Real implementation
class MacSystemActions: SystemActionsProtocol {
    func lockScreen() throws {
        // Actual system calls
    }
}

// Mock for testing
class MockSystemActions: SystemActionsProtocol {
    var lockScreenCalled = false
    func lockScreen() throws {
        lockScreenCalled = true
    }
}

// Service using the protocol
class SecurityActionsService {
    private let systemActions: SystemActionsProtocol
    
    init(systemActions: SystemActionsProtocol = MacSystemActions()) {
        self.systemActions = systemActions
    }
}
```

#### Example: Authentication Context

```swift
// Protocol for authentication
protocol AuthenticationContextProtocol {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws
    var biometryType: LABiometryType { get }
}

// Factory pattern for creating contexts
protocol AuthenticationContextFactoryProtocol {
    func createContext() -> AuthenticationContextProtocol
}
```

### Extracting Testable Logic

#### Before (Untestable)

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // Crashes in tests
        statusItem = NSStatusBar.system.statusItem(...) // Requires NSApp
        // Business logic mixed with UI
    }
}
```

#### After (Testable)

```swift
// Extract business logic
class AppDelegateCore {
    func createMenu() -> NSMenu { ... }
    func handlePowerStateChange(_ info: PowerInfo) -> Bool { ... }
}

// Thin UI layer
class AppDelegate: NSObject, NSApplicationDelegate {
    let core = AppDelegateCore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.menu = core.createMenu()
    }
}
```

## Testing Strategies by Component

### Authentication Service

**Strategy**: Use mock LAContext to test all authentication flows

```swift
// Test setup
let mockContext = MockAuthenticationContext()
let mockFactory = MockAuthenticationContextFactory(mockContext: mockContext)
let service = AuthenticationService(contextFactory: mockFactory)

// Test success path
mockContext.evaluatePolicyShouldSucceed = true
service.authenticate(reason: "Test") { result in
    XCTAssertEqual(result, .success)
}

// Test failure path
mockContext.evaluatePolicyError = LAError(.authenticationFailed)
service.authenticate(reason: "Test") { result in
    XCTAssertEqual(result, .failure(.authenticationFailed))
}
```

### Security Actions Service

**Strategy**: Mock system calls to test action coordination

```swift
// Test setup
let mockSystemActions = MockSystemActions()
let service = SecurityActionsService(systemActions: mockSystemActions)

// Test action execution
service.executeActions { result in
    XCTAssertTrue(mockSystemActions.lockScreenCalled)
    XCTAssertTrue(result.allSucceeded)
}
```

### Power Monitoring

**Strategy**: Extract power state logic from IOKit dependencies

```swift
// Testable core logic
class PowerMonitorCore {
    func processPowerSourceInfo(_ info: [String: Any]) -> PowerInfo { ... }
    func hasPowerStateChanged(newInfo: PowerInfo) -> Bool { ... }
}

// IOKit integration (excluded from coverage)
class PowerMonitorService {
    private let core = PowerMonitorCore()
    // Thin wrapper around IOKit
}
```

## Test Organization

### Unit Tests

Location: `MagSafeGuardTests/`

- **MockTests**: Tests using mocks for 100% coverage
  - `AuthenticationServiceMockTests.swift`
  - `SecurityActionsServiceTests.swift`
  - `AppDelegateCoreTests.swift`

- **Integration Tests**: Tests with some real components
  - `PowerMonitorServiceTests.swift`
  - `PowerMonitorCoreTests.swift`

### Manual Acceptance Tests

Location: `docs/maintainers/acceptance-tests.md`

Cover real system integration that cannot be automated:

- Actual biometric authentication
- Real screen locking
- System shutdown/logout
- Hardware power disconnection

## Running Tests

### Using Taskfile (Recommended)

The project includes a comprehensive Taskfile with test commands:

```bash
# Run all tests
task test

# Run tests with coverage report
task test:coverage

# Generate HTML coverage report
task test:coverage:html

# Run specific test file
task test -- --filter SecurityActionsServiceTests

# Run tests
task test
```

### Manual Test Commands

```bash
# Basic test run
swift test

# With coverage
swift test --enable-code-coverage

# Generate coverage report
xcrun llvm-cov report \
  .build/*/debug/MagSafeGuardPackageTests.xctest/Contents/MacOS/MagSafeGuardPackageTests \
  -instr-profile=.build/*/debug/codecov/default.profdata \
  -ignore-filename-regex=".*Tests\.swift|.*Mock.*\.swift"
```

### Environment Variables

The test suite recognizes these environment variables:

- **`CI=true`**: (Deprecated - no longer needed with protocol-based testing)
  - Previously used to skip authentication dialogs
  - No longer required since tests use mocks

- **`SKIP_UI_TESTS=true`**: Skip UI-dependent tests

- **`COVERAGE_THRESHOLD=80`**: Set minimum coverage requirement

Example:

```bash
COVERAGE_THRESHOLD=85 task test:coverage
```

## Writing Effective Tests

### Test Structure

```swift
func testFeatureBehavior() {
    // Arrange: Set up test conditions
    mockService.configureExpectedBehavior()
    
    // Act: Execute the feature
    let result = service.performAction()
    
    // Assert: Verify the outcome
    XCTAssertTrue(result.succeeded)
    XCTAssertTrue(mockService.expectedMethodCalled)
}
```

### Async Testing

```swift
func testAsyncOperation() {
    let expectation = self.expectation(description: "Async operation completes")
    
    service.performAsyncOperation { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    waitForExpectations(timeout: 2)
}
```

### Testing Error Paths

```swift
func testErrorHandling() {
    // Configure mock to fail
    mockService.shouldFail = true
    mockService.errorToThrow = CustomError.networkFailure
    
    // Verify error is handled correctly
    service.performOperation { result in
        switch result {
        case .failure(let error):
            XCTAssertEqual(error as? CustomError, .networkFailure)
        case .success:
            XCTFail("Should have failed")
        }
    }
}
```

## Coverage Exclusions

### Files to Exclude

1. **UI-Dependent Code**
   - `MagSafeGuardApp.swift` - NSApp dependencies
   - `*View.swift` - SwiftUI views (test view models instead)

2. **System Integration Code**
   - `*LAContext.swift` - Direct LAContext usage
   - `Mac*Actions.swift` - Real system implementations
   - `PowerMonitorService.swift` - IOKit integration

3. **Test Infrastructure**
   - `*Tests.swift` - Test files
   - `Mock*.swift` - Mock implementations
   - `runner.swift` - Test runner

### Exclusion Configuration

Configure in multiple places:

1. **Taskfile.yml**:

```yaml
test:coverage:
  cmds:
    - swift test --enable-code-coverage
    - |
      xcrun llvm-cov report ... \
        -ignore-filename-regex=".*Tests\.swift|.*Mocks?\.swift|.*/MagSafeGuardApp\.swift"
```

1. **sonar-project.properties**:

```properties
sonar.coverage.exclusions=\
  **/MagSafeGuardApp.swift,\
  **/PowerMonitorService.swift,\
  **/PowerMonitorCore.swift,\
  **/*LAContext.swift,\
  **/Mac*Actions.swift,\
  **/*Tests.swift,\
  **/Mock*.swift
```

1. **.codecov.yml**:

```yaml
coverage:
  ignore:
    - "Tests/"
    - "**/Mock*.swift"
    - "**/MagSafeGuardApp.swift"
```

## CI/CD Integration

### GitHub Actions Configuration

```yaml
- name: Run Tests with Coverage
  env:
    CI: true
  run: |
    # Install dependencies
    brew install go-task/tap/go-task
    
    # Run tests with coverage
    task test:coverage
    
    # Upload to codecov
    bash <(curl -s https://codecov.io/bash)
```

### SonarCloud Integration

The coverage report is automatically converted to SonarQube format:

```bash
# Conversion happens in test:coverage task
task test:convert  # Converts LCOV to SonarQube XML
```

## Best Practices

### DO

- ✅ Extract business logic into testable classes
- ✅ Use dependency injection with protocols
- ✅ Test all success and failure paths
- ✅ Mock external dependencies
- ✅ Write tests before fixing bugs
- ✅ Keep tests fast and isolated
- ✅ Use proper mocks for automated testing

### DON'T

- ❌ Test implementation details
- ❌ Mock types you own (use real objects)
- ❌ Write tests that depend on timing
- ❌ Test UI layout in unit tests
- ❌ Execute real system actions in tests
- ❌ Hardcode paths in tests

## Troubleshooting

### Common Issues

1. **"Authentication dialog appears during tests"**
   - Ensure you're using mock authentication context
   - Ensure mock authentication context is used
   - Verify mock factory is properly injected

2. **"Tests timeout in CI"**
   - Add explicit timeouts to async tests
   - Mock time-dependent operations
   - Use explicit timeouts in async tests

3. **"Coverage is lower than expected"**
   - Check exclusion patterns in Taskfile
   - Ensure all test files are being run
   - Verify mock usage in tests
   - Run `task test:coverage:html` to see detailed report

4. **"Screen locks during test run"**
   - Ensure SecurityActionsService uses mock
   - Check AppDelegateCore initialization
   - Verify test uses dependency injection

### Debugging Tips

```swift
// Add verbose logging in tests
XCTContext.runActivity(named: "Testing authentication") { _ in
    print("Mock state: \(mockContext)")
    // Test code here
}

// Use afterEach to verify mock state
override func tearDown() {
    XCTAssertFalse(mockService.hasUnexpectedCalls)
    super.tearDown()
}

// Tests now work the same locally and in CI
// No special environment checks needed
```

## Future Improvements

1. **Property-Based Testing**: Use SwiftCheck for randomized testing
2. **Snapshot Testing**: Add UI snapshot tests for views
3. **Performance Testing**: Add XCTest performance tests
4. **Integration Test Suite**: Separate integration tests from unit tests
5. **Test Data Builders**: Create builders for complex test objects
6. **Mutation Testing**: Use tools to verify test quality
7. **Contract Testing**: Ensure mocks match real implementations
