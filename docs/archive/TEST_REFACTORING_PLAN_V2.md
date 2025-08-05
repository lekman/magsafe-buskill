# Test Refactoring Plan V2: Protocol-Based Testing Architecture

## Executive Summary

This plan outlines a comprehensive approach to achieve near 100% test coverage for MagSafe Guard's business logic while maintaining clear separation from macOS system integration. Following the Swift project architecture best practices documented in `docs/architecture/swift-project-architecture-practices.md`, we'll implement a protocol-based testing strategy that isolates testable business logic from system dependencies.

## Current State Analysis

### Test Coverage Gaps

Based on the project structure and existing tests:

1. **Currently Tested (Limited Coverage)**:

   - `FeatureFlags` (has tests but failing)
   - `SettingsModel` (basic tests)
   - `Logger` (89.25% coverage)

2. **Backup Tests Available** (Need Protocol Refactoring):

   - PowerMonitorCore/Service
   - AuthenticationService
   - SecurityActionsService
   - AutoArmManager
   - LocationManager
   - NetworkMonitor
   - NotificationService
   - SyncService components

3. **Missing Business Logic Tests**:
   - AppController orchestration logic
   - AppDelegateCore business rules
   - Service interaction logic
   - State management logic

### Architecture Issues

1. **Mixed Concerns**: Business logic is intertwined with system integration
2. **Direct Dependencies**: Services directly use system APIs (IOKit, CoreLocation, etc.)
3. **Limited Mocking**: Incomplete protocol abstractions for testing
4. **SPM vs Xcode Conflict**: Tests structured for Xcode but running in SPM

## Target Architecture

Following the Swift best practices guide, we'll implement:

### 1. Clean Architecture Layers

```swift
// Domain Layer (100% Testable)
protocol PowerMonitorUseCase {
    func detectPowerStateChange() async -> PowerStateChange?
    func evaluateSecurityThreat(change: PowerStateChange) -> ThreatLevel
}

// Data Layer (Mockable)
protocol PowerSourceRepository {
    func getCurrentPowerState() async -> PowerState
    func observePowerChanges() -> AsyncStream<PowerState>
}

// Presentation Layer (Testable ViewModels)
class PowerMonitorViewModel: ObservableObject {
    private let useCase: PowerMonitorUseCase
    @Published var threatLevel: ThreatLevel = .none
}
```

### 2. Feature-Based Test Structure

```ini
Tests/
├── Unit/                           # Pure business logic tests
│   ├── Features/
│   │   ├── PowerMonitoring/
│   │   │   ├── PowerMonitorUseCaseTests.swift
│   │   │   ├── PowerStateAnalyzerTests.swift
│   │   │   └── ThreatEvaluatorTests.swift
│   │   ├── Authentication/
│   │   │   ├── AuthenticationUseCaseTests.swift
│   │   │   ├── BiometricPolicyTests.swift
│   │   │   └── AuthenticationFlowTests.swift
│   │   ├── SecurityActions/
│   │   │   ├── SecurityActionUseCaseTests.swift
│   │   │   ├── ActionQueueManagerTests.swift
│   │   │   └── ActionPriorityTests.swift
│   │   └── AutoArm/
│   │       ├── AutoArmUseCaseTests.swift
│   │       ├── LocationRulesEngineTests.swift
│   │       └── NetworkTrustEvaluatorTests.swift
│   ├── Shared/
│   │   ├── Models/
│   │   ├── Utilities/
│   │   └── Extensions/
│   └── TestHelpers/
│       ├── Builders/               # Test data builders
│       ├── Fixtures/               # Test data fixtures
│       └── Assertions/             # Custom assertions
├── Integration/                    # Component interaction tests
│   └── UseCaseIntegrationTests/
└── System/                        # macOS system tests (manual)
```

## Swift Testing Migration Strategy

### Why Swift Testing?

As documented in the Swift project architecture best practices, Apple's new Swift Testing framework (introduced at WWDC 2024) provides significant improvements over XCTest:

1. **Better Syntax**: More expressive and readable test declarations
2. **Parameterized Tests**: Built-in support for data-driven testing
3. **Improved Async Support**: Native async/await integration
4. **Better Error Messages**: More descriptive failure messages
5. **Performance**: Parallel test execution by default
6. **Modern API**: Designed for Swift from the ground up

### Migration Approach

We'll adopt a gradual migration strategy:

1. **New Tests**: All new tests will be written using Swift Testing
2. **Refactored Tests**: As we refactor existing tests, convert to Swift Testing
3. **Legacy Tests**: Keep working XCTest tests until refactored
4. **Hybrid Support**: Both frameworks can coexist during migration

### Key Differences

| XCTest                     | Swift Testing                  |
| -------------------------- | ------------------------------ |
| `XCTAssertEqual(a, b)`     | `#expect(a == b)`              |
| `XCTAssertTrue(condition)` | `#expect(condition)`           |
| `XCTAssertThrows`          | `#expect(throws:)`             |
| `func testExample()`       | `@Test("Example description")` |
| `XCTestCase` class         | `struct` with `@Suite`         |
| `setUp()/tearDown()`       | `init()/deinit()`              |
| Manual parameterization    | `@Test(arguments:)`            |

### Swift Testing Features for MagSafe Guard

```swift
import Testing

// Test Suites with Tags
@Suite("Security Features", .tags(.security, .critical))
struct SecurityTests {
    // Shared setup in init
    let mockAuthenticator: MockAuthenticator

    init() {
        mockAuthenticator = MockAuthenticator()
    }
}

// Parameterized Tests
@Test("Power state transitions", arguments: PowerStateTransitions.all)
func validateTransition(from: PowerState, to: PowerState, expected: TransitionType) {
    let transition = PowerAnalyzer.analyze(from: from, to: to)
    #expect(transition.type == expected)
}

// Conditional Tests
@Test("Biometric authentication", .enabled(if: BiometricCapability.isAvailable))
func authenticateWithBiometrics() async throws {
    let result = try await authenticator.authenticate()
    #expect(result.isSuccess)
}

// Known Issues
@Test("Flaky network test")
func networkDetection() async throws {
    await withKnownIssue("Fails in CI environment") {
        let network = try await detector.detectNetwork()
        #expect(network.isTrusted)
    }
}
```

## Implementation Plan

### Phase 1: Protocol Extraction (Week 1)

#### 1.1 Define Core Business Protocols

```swift
// PowerMonitoring/Domain/PowerMonitorProtocols.swift
protocol PowerStateAnalyzer {
    func analyzePowerChange(from: PowerState, to: PowerState) -> PowerChangeAnalysis
}

protocol ThreatEvaluator {
    func evaluateThreat(analysis: PowerChangeAnalysis, context: SecurityContext) -> ThreatLevel
}

protocol SecurityActionDecider {
    func determineActions(threat: ThreatLevel, settings: SecuritySettings) -> [SecurityAction]
}
```

#### 1.2 Extract Business Logic from Services

**Before (Current)**:

```swift
class PowerMonitorService {
    func startMonitoring() {
        // Mixed IOKit calls and business logic
        let snapshot = IOPSCopyPowerSourcesInfo()
        // ... complex logic mixed with system calls
    }
}
```

**After (Target)**:

```swift
// Business Logic (100% Testable)
class PowerMonitorUseCase {
    private let repository: PowerSourceRepository
    private let analyzer: PowerStateAnalyzer
    private let evaluator: ThreatEvaluator

    func processPowerChange(newState: PowerState) -> SecurityDecision {
        let analysis = analyzer.analyzePowerChange(from: lastState, to: newState)
        let threat = evaluator.evaluateThreat(analysis, context: currentContext)
        return SecurityDecision(threat: threat, requiredActions: determineActions(threat))
    }
}

// System Integration (Thin Layer, Not Unit Tested)
class IOKitPowerSourceRepository: PowerSourceRepository {
    func getCurrentPowerState() async -> PowerState {
        // IOKit calls only, no business logic
    }
}
```

### Phase 2: Test Infrastructure (Week 1)

#### 2.1 Test Builders Pattern

```swift
// TestHelpers/Builders/PowerStateBuilder.swift
class PowerStateBuilder {
    private var state = PowerState.default

    func withACPower(_ connected: Bool) -> PowerStateBuilder {
        state.isACConnected = connected
        return self
    }

    func withBatteryLevel(_ level: Int) -> PowerStateBuilder {
        state.batteryLevel = level
        return self
    }

    func build() -> PowerState { state }
}

// Usage in tests
let disconnectedState = PowerStateBuilder()
    .withACPower(false)
    .withBatteryLevel(85)
    .build()
```

#### 2.2 Custom Expectations (Swift Testing)

```swift
// TestHelpers/Expectations/SecurityExpectations.swift
import Testing

@discardableResult
func expectThreatLevel(
    _ expression: @autoclosure () throws -> ThreatLevel,
    equals expected: ThreatLevel,
    sourceLocation: SourceLocation = #_sourceLocation
) -> Bool {
    do {
        let actual = try expression()
        return expect(actual == expected,
                     "Expected threat level \(expected), got \(actual)",
                     sourceLocation: sourceLocation)
    } catch {
        Issue.record("Expression threw error: \(error)",
                    sourceLocation: sourceLocation)
        return false
    }
}

// Usage in tests
@Test func threatLevelTest() {
    let threat = analyzer.analyze(situation)
    expectThreatLevel(threat, equals: .high)
}
```

#### 2.3 Comprehensive Mocks

```swift
// TestHelpers/Mocks/MockPowerSourceRepository.swift
class MockPowerSourceRepository: PowerSourceRepository {
    // Controllable behavior
    var powerStateSequence: [PowerState] = []
    var shouldThrowError = false
    var delayMilliseconds = 0

    // Verification
    private(set) var getCurrentStateCallCount = 0
    private(set) var observeCallCount = 0

    func getCurrentPowerState() async -> PowerState {
        getCurrentStateCallCount += 1
        if shouldThrowError { throw PowerError.unavailable }
        if delayMilliseconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayMilliseconds * 1_000_000))
        }
        return powerStateSequence.first ?? .disconnected
    }
}
```

### Phase 3: Business Logic Tests (Week 2)

#### 3.1 Power Monitoring Tests (Swift Testing)

```swift
import Testing
@testable import MagSafeGuardDomain

@Suite("Power Monitor Use Case")
struct PowerMonitorUseCaseTests {
    let mockRepository: MockPowerSourceRepository
    let mockAnalyzer: MockPowerStateAnalyzer
    let sut: PowerMonitorUseCase

    init() {
        mockRepository = MockPowerSourceRepository()
        mockAnalyzer = MockPowerStateAnalyzer()
        sut = PowerMonitorUseCase(
            repository: mockRepository,
            analyzer: mockAnalyzer
        )
    }

    @Test("Detects AC power disconnection")
    func detectsACDisconnection() async {
        // Given
        mockRepository.powerStateSequence = [
            .connected,
            .disconnected
        ]

        // When
        let change = await sut.detectPowerStateChange()

        // Then
        #expect(change?.type == .acDisconnected)
        #expect(mockRepository.getCurrentStateCallCount == 2)
    }

    @Test("Evaluates high threat for unexpected disconnection while armed")
    func evaluatesHighThreatForUnexpectedDisconnection() {
        // Given
        let change = PowerStateChange(
            from: .connected,
            to: .disconnected,
            timestamp: Date()
        )
        let context = SecurityContext(isArmed: true, location: .untrusted)

        // When
        let threat = sut.evaluateThreat(change: change, context: context)

        // Then
        #expect(threat == .high)
    }

    @Test("Power state changes", arguments: [
        (PowerState.connected, PowerState.disconnected, PowerChangeType.acDisconnected),
        (PowerState.disconnected, PowerState.connected, PowerChangeType.acConnected),
        (PowerState.charging(50), PowerState.charging(75), PowerChangeType.batteryLevelChanged)
    ])
    func detectsVariousPowerStateChanges(from: PowerState, to: PowerState, expectedType: PowerChangeType) {
        // When
        let change = sut.analyzePowerChange(from: from, to: to)

        // Then
        #expect(change.type == expectedType)
    }
}
```

#### 3.2 Authentication Flow Tests (Swift Testing)

```swift
import Testing
@testable import MagSafeGuardDomain

@Suite("Authentication Use Case")
struct AuthenticationUseCaseTests {

    @Test("Requires biometric authentication for high security actions")
    func requiresBiometricForHighSecurityActions() async {
        // Given
        let useCase = AuthenticationUseCase(policy: .alwaysRequireBiometric)
        let action = SecurityAction.lockScreen

        // When
        let requirement = await useCase.authenticationRequirement(for: action)

        // Then
        #expect(requirement == .biometric)
    }

    @Test("Caches authentication for grace period")
    func cachesAuthenticationForGracePeriod() async throws {
        // Given
        let useCase = AuthenticationUseCase(
            policy: .cacheAuthentication,
            gracePeriod: .seconds(30)
        )

        // When
        try await useCase.authenticate(method: .biometric)
        let secondAuth = await useCase.isAuthenticated()

        // Then
        #expect(secondAuth == true)
    }

    @Test("Authentication policies", arguments: [
        (AuthPolicy.alwaysRequireBiometric, true),
        (AuthPolicy.allowPasswordFallback, false),
        (AuthPolicy.skipInSafeMode, false)
    ])
    func enforcesAuthenticationPolicies(policy: AuthPolicy, requiresBiometric: Bool) {
        let useCase = AuthenticationUseCase(policy: policy)
        #expect(useCase.requiresBiometricOnly == requiresBiometric)
    }
}
```

#### 3.3 Security Action Tests (Swift Testing)

```swift
import Testing
@testable import MagSafeGuardDomain

@Suite("Security Action Use Case")
struct SecurityActionUseCaseTests {

    @Test("Prioritizes security actions by severity")
    func prioritizesActionsCorrectly() {
        // Given
        let actions: [SecurityAction] = [
            .playSound,
            .lockScreen,
            .shutdown
        ]

        // When
        let prioritized = SecurityActionPrioritizer.prioritize(actions)

        // Then
        #expect(prioritized.first == .lockScreen)
        #expect(prioritized.last == .shutdown)
    }

    @Test("Queues actions with configurable delay")
    func queuesActionsWithDelay() async {
        // Given
        let queue = SecurityActionQueue()
        let action = SecurityAction.lockScreen

        // When
        queue.enqueue(action, delay: .seconds(5))

        // Then
        #expect(queue.pendingCount == 1)
        #expect(queue.isExecuting == false)
    }

    @Test("Action combinations", arguments: [
        ([.lockScreen, .playSound], 2),
        ([.shutdown], 1),
        ([.lockScreen, .shutdown, .playSound], 2) // Shutdown cancels others
    ])
    func validatesActionCombinations(actions: [SecurityAction], expectedCount: Int) {
        let validated = SecurityActionValidator.validate(actions)
        #expect(validated.count == expectedCount)
    }
}
```

### Phase 4: Integration Tests (Week 3)

#### 4.1 Use Case Integration (Swift Testing)

```swift
import Testing
@testable import MagSafeGuardDomain

@Suite("Security Flow Integration", .serialized)
struct PowerSecurityIntegrationTests {

    @Test("Complete security flow from power disconnection", .timeLimit(.minutes(1)))
    func fullSecurityFlowFromPowerDisconnection() async throws {
        // Given
        let powerMonitor = PowerMonitorUseCase(/* mocks */)
        let authenticator = AuthenticationUseCase(/* mocks */)
        let actionExecutor = SecurityActionUseCase(/* mocks */)

        let coordinator = SecurityCoordinator(
            powerMonitor: powerMonitor,
            authenticator: authenticator,
            actionExecutor: actionExecutor
        )

        // When
        await coordinator.handlePowerChange(.disconnected)

        // Then
        #expect(authenticator.wasPrompted == true)
        #expect(actionExecutor.executedActions == [.lockScreen])
    }

    @Test("Handles authentication failure gracefully")
    func handlesAuthenticationFailure() async throws {
        // Given
        let coordinator = createCoordinator(authShouldFail: true)

        // When/Then - should not throw
        await coordinator.handlePowerChange(.disconnected)

        #expect(coordinator.lastError != nil)
        #expect(coordinator.fallbackActionExecuted == true)
    }
}
```

### Phase 5: SPM Test Configuration (Week 4)

#### 5.1 Update Package.swift for Swift Testing

```swift
// Package.swift
import PackageDescription

let package = Package(
    name: "MagSafeGuard",
    platforms: [.macOS(.v14)], // Required for Swift Testing
    products: [
        .library(name: "MagSafeGuardCore", targets: ["MagSafeGuardCore"]),
        .library(name: "MagSafeGuardDomain", targets: ["MagSafeGuardDomain"]),
    ],
    dependencies: [
        // Swift Testing is included in Swift 5.10+
        // No external dependency needed
    ],
    targets: [
        // Business Logic (100% tested)
        .target(
            name: "MagSafeGuardDomain",
            dependencies: [],
            path: "Sources/Domain"
        ),

        // Data Layer (Mockable)
        .target(
            name: "MagSafeGuardCore",
            dependencies: ["MagSafeGuardDomain"],
            path: "Sources/Core"
        ),

        // Tests using Swift Testing
        .testTarget(
            name: "MagSafeGuardDomainTests",
            dependencies: [
                "MagSafeGuardDomain",
                .product(name: "Testing", package: "swift-testing") // If using older Swift
            ],
            path: "Tests/Unit"
        ),

        // Legacy XCTest tests during migration
        .testTarget(
            name: "MagSafeGuardLegacyTests",
            dependencies: ["MagSafeGuardCore"],
            path: "Tests/Legacy"
        ),
    ]
)
```

#### 5.2 CI-Safe Test Configuration with Swift Testing

```swift
// Tests/TestConfiguration.swift
import Testing

struct TestConfiguration {
    static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] == "true"
    }

    static var testTimeout: Duration {
        isCI ? .seconds(10) : .seconds(30)
    }

    static var skipIntegrationTests: Bool {
        isCI || ProcessInfo.processInfo.environment["SKIP_INTEGRATION"] == "true"
    }
}

// Custom test traits for CI
extension Trait where Self == TimeLimitTrait {
    static var ciTimeout: Self { .timeLimit(TestConfiguration.testTimeout) }
}

extension Trait where Self == EnabledTrait {
    static var skipInCI: Self { .enabled(if: !TestConfiguration.isCI) }
}

// Usage in tests
@Test("System integration test", .skipInCI, .ciTimeout)
func systemIntegrationTest() async throws {
    // This test only runs locally, not in CI
}
```

#### 5.3 Running Swift Testing

```bash
# Command line
swift test

# With specific filter
swift test --filter "PowerMonitor"

# Parallel execution (default in Swift Testing)
swift test --parallel

# With verbose output
swift test --verbose

# Generate JUnit XML for CI
swift test --xunit-output results.xml
```

## Test Coverage Targets

### Phase 1-2 Target (Foundation)

- Protocol definitions: N/A (interfaces)
- Test infrastructure: N/A (test code)

### Phase 3 Target (Business Logic)

- Domain Use Cases: **95-100%**
- Business Rules: **95-100%**
- State Management: **90-95%**
- Data Models: **100%**

### Phase 4 Target (Integration)

- Use Case Integration: **80-90%**
- Service Orchestration: **80-90%**

### Excluded from Coverage

- System Integration Layer (IOKit, CoreLocation, etc.)
- SwiftUI Views
- AppDelegate/SceneDelegate bootstrap code
- Mock implementations

## Success Metrics

1. **Coverage Goals**:

   - Overall project: 80%+
   - Business logic: 95%+
   - Critical paths: 100%

2. **Test Quality**:

   - All tests run in < 30 seconds
   - No flaky tests
   - Clear test names describing behavior
   - Each test verifies one behavior

3. **Architecture Quality**:
   - Clear separation of concerns
   - No business logic in system integration layer
   - All dependencies injected
   - All external calls mockable

## Migration Strategy

### Week 1: Foundation

1. Create protocol definitions
2. Set up test infrastructure
3. Migrate PowerMonitorCore tests

### Week 2: Core Services

1. Extract AuthenticationService business logic
2. Extract SecurityActionsService business logic
3. Create comprehensive test suites

### Week 3: Orchestration

1. Extract AppController business logic
2. Test service coordination
3. Integration test suite

### Week 4: Polish

1. Address coverage gaps
2. Performance optimization
3. Documentation

## Testing Best Practices

### 1. Test Naming Convention (Swift Testing)

```swift
// Swift Testing uses descriptive strings instead of method names
@Test("Evaluates high threat when armed and disconnected")
func evaluateThreatScenario() {
    // Test implementation
}

// Or with parameterized tests
@Test("Threat evaluation", arguments: [
    (armed: true, connected: false, expectedThreat: .high),
    (armed: false, connected: false, expectedThreat: .low)
])
func evaluatesThreatCorrectly(armed: Bool, connected: Bool, expectedThreat: ThreatLevel) {
    // Test implementation
}
```

### 2. AAA Pattern with Swift Testing

```swift
@Test("Processes input correctly")
func processesInput() {
    // Arrange
    let sut = createSUT()
    let input = createInput()

    // Act
    let result = sut.process(input)

    // Assert (using #expect)
    #expect(result == expected)
    #expect(result.count == 5)
    #expect(throws: ValidationError.self) {
        try sut.process(invalidInput)
    }
}
```

### 3. Test Data Builders

```swift
extension PowerState {
    static func connected(batteryLevel: Int = 100) -> PowerState {
        PowerStateBuilder()
            .withACPower(true)
            .withBatteryLevel(batteryLevel)
            .build()
    }
}
```

### 4. Async Testing with Swift Testing

```swift
@Test("Performs async operations", .timeLimit(.seconds(5)))
func asyncBehavior() async throws {
    // Swift Testing has built-in async support
    let result = await sut.performAsyncOperation()
    #expect(result == expected)

    // Test async sequences
    var values: [Int] = []
    for await value in sut.asyncSequence() {
        values.append(value)
    }
    #expect(values == [1, 2, 3])
}

// With timeout expectations
@Test("Completes within timeout")
func timeSensitiveOperation() async throws {
    await withKnownIssue {
        // This might timeout in CI
        let result = await sut.slowOperation()
        #expect(result != nil)
    }
}
```

## Swift Testing Benefits for MagSafe Guard

By migrating to Swift Testing, we gain several specific advantages for this project:

1. **Parameterized Security Tests**: Test multiple threat scenarios efficiently

   ```swift
   @Test("Threat scenarios", arguments: ThreatScenarios.all)
   func evaluatesThreat(scenario: ThreatScenario) {
       #expect(evaluator.assess(scenario) == scenario.expectedLevel)
   }
   ```

2. **Better Async Testing**: Natural support for our async security operations

   ```swift
   @Test("Authenticates within timeout", .timeLimit(.seconds(30)))
   func authentication() async throws {
       let result = try await authenticator.authenticate()
       #expect(result.isSuccess)
   }
   ```

3. **Tagged Test Organization**: Group tests by feature or criticality

   ```swift
   @Suite("Critical Security", .tags(.security, .critical))
   ```

4. **Conditional Testing**: Skip tests based on environment

   ```swift
   @Test("Biometric test", .enabled(if: !TestConfiguration.isCI))
   ```

5. **Better Failure Diagnostics**: More informative error messages for debugging

## Conclusion

This plan provides a clear path to achieve near 100% test coverage for business logic while adopting Apple's modern Swift Testing framework. By separating business logic from system integration, using protocol-based design, and leveraging Swift Testing's features, we can create a robust, testable codebase that follows the latest Swift best practices.

The migration to Swift Testing aligns with the framework recommendations in our architecture guide and provides a more modern, maintainable test suite. The key is maintaining discipline in the separation of concerns and ensuring all business logic is extracted into testable components.

---

_Last Updated: August 3, 2025_
_Next Review: After Phase 1 completion_
