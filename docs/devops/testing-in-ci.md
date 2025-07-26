# Testing in CI/CD Environments

## Protocol-Based Testing Strategy

MagSafe Guard uses a protocol-based testing approach that ensures tests run identically in all environments - local development, simulators, and CI/CD pipelines.

### Key Principles

1. **No Real System Calls**: All system interactions are abstracted behind protocols
2. **Mock Everything External**: Tests use mock implementations exclusively
3. **Deterministic Behavior**: Tests produce the same results everywhere
4. **No Environment Variables**: CI=true is no longer needed

### Authentication Service Tests

The `AuthenticationService` uses protocol abstractions instead of real `LAContext`:

```swift
// Protocol for authentication context
protocol AuthenticationContextProtocol {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws
    var biometryType: LABiometryType { get }
}

// Mock implementation for tests
class MockAuthenticationContext: AuthenticationContextProtocol {
    var canEvaluatePolicyResult = true
    var evaluatePolicyShouldSucceed = true
    // ... mock behavior configuration
}
```

## Test Behavior Consistency

### Same Behavior Everywhere

With protocol-based testing, tests behave identically in:

- Local development (any Mac)
- Xcode simulators
- GitHub Actions CI runners
- Any other CI/CD platform

### Test Examples

1. **Biometric Availability Tests**

   ```swift
   mockContext.canEvaluatePolicyResult = true
   mockContext.biometryType = .touchID
   XCTAssertTrue(service.isBiometricAuthenticationAvailable)
   ```

2. **Authentication Flow Tests**

   ```swift
   mockContext.evaluatePolicyShouldSucceed = true
   service.authenticate(reason: "Test") { result in
       XCTAssertEqual(result, .success)
   }
   ```

3. **Error Handling Tests**

   ```swift
   mockContext.evaluatePolicyError = LAError(.authenticationFailed)
   service.authenticate(reason: "Test") { result in
       XCTAssertEqual(result, .failure(.authenticationFailed))
   }
   ```

### Benefits

1. **Predictable Results**
   - Tests always produce the same outcome
   - No environment-specific workarounds
   - Easier debugging

2. **Fast Execution**
   - No system dialogs or timeouts
   - No hardware dependencies
   - Instant mock responses

3. **Complete Coverage**
   - Test all code paths
   - Simulate any hardware configuration
   - Test error conditions easily

## Running Tests

Tests run the same way everywhere:

```bash
# Run all tests
swift test

# Run specific tests
swift test --filter AuthenticationServiceTests

# Run with coverage
swift test --enable-code-coverage
```

No special CI flags or environment variables needed!

## Architecture Overview

### C4 Context Diagram - Testing System Overview

```mermaid
graph TB
    subgraph "Testing Ecosystem"
        DEV[Developer]
        CI[CI/CD System]
        
        subgraph "MagSafe Guard Test Suite"
            TS[Test Suite<br/>Protocol-Based Tests]
        end
        
        subgraph "External Systems"
            GH[GitHub Actions]
            XC[Xcode Cloud]
            LOCAL[Local Machine]
        end
        
        DEV -->|writes tests| TS
        DEV -->|runs tests| LOCAL
        CI -->|triggers| GH
        CI -->|triggers| XC
        GH -->|executes| TS
        XC -->|executes| TS
        LOCAL -->|executes| TS
        
        TS -->|produces| REP[Test Reports<br/>Coverage Metrics]
    end
    
    style DEV fill:#bbdefb
    style CI fill:#c5cae9
    style TS fill:#c8e6c9
    style GH fill:#ffccbc
    style XC fill:#ffccbc
    style LOCAL fill:#ffccbc
    style REP fill:#fff9c4
```

### C4 Component Diagram - Testing Architecture

```mermaid
graph TB
    subgraph "MagSafe Guard Testing Architecture"
        subgraph "Authentication Service Layer"
            AS[AuthenticationService<br/>Business Logic]
            ACP[AuthenticationContextProtocol<br/>Protocol Interface]
            MAC[MockAuthenticationContext<br/>Test Implementation]
            LAC[LAContextWrapper<br/>Real Implementation]
            
            AS -->|depends on| ACP
            MAC -->|implements| ACP
            LAC -->|implements| ACP
            MAC -.->|used in tests| AS
            LAC -.->|used in production| AS
        end
        
        subgraph "Security Actions Layer"
            SAS[SecurityActionsService<br/>Business Logic]
            SAP[SystemActionsProtocol<br/>Protocol Interface]
            MSA[MockSystemActions<br/>Test Implementation]
            MAS[MacSystemActions<br/>Real Implementation]
            
            SAS -->|depends on| SAP
            MSA -->|implements| SAP
            MAS -->|implements| SAP
            MSA -.->|used in tests| SAS
            MAS -.->|used in production| SAS
        end
        
        subgraph "Test Environment"
            UT[Unit Tests]
            CI[CI/CD Pipeline]
            
            UT -->|uses| MAC
            UT -->|uses| MSA
            CI -->|runs| UT
        end
    end
    
    style AS fill:#e1f5fe
    style SAS fill:#e1f5fe
    style ACP fill:#fff9c4
    style SAP fill:#fff9c4
    style MAC fill:#c8e6c9
    style MSA fill:#c8e6c9
    style LAC fill:#ffccbc
    style MAS fill:#ffccbc
    style UT fill:#f3e5f5
    style CI fill:#f3e5f5
```

### C4 Container Diagram - Test Execution Flow

```mermaid
graph LR
    subgraph "Development Environment"
        DEV[Developer<br/>Machine]
        XC[Xcode]
    end
    
    subgraph "CI/CD Environment"
        GHA[GitHub Actions<br/>Runner]
        COV[Coverage<br/>Reports]
    end
    
    subgraph "Test Suite"
        TST[Swift Tests<br/>Protocol-Based]
        MCK[Mock<br/>Implementations]
    end
    
    DEV -->|swift test| TST
    XC -->|runs| TST
    GHA -->|swift test| TST
    TST -->|uses| MCK
    TST -->|generates| COV
    
    style DEV fill:#e3f2fd
    style XC fill:#e3f2fd
    style GHA fill:#f3e5f5
    style COV fill:#f3e5f5
    style TST fill:#e8f5e9
    style MCK fill:#fff9c4
```

## Coverage Strategy

1. **Test Business Logic**: 100% coverage target for service classes
2. **Mock External Dependencies**: Use protocol-based mocks
3. **Exclude System Integration**: Real implementations excluded from coverage
4. **Manual Acceptance Tests**: Document in acceptance-tests.md

## See Also

- [Testing Guide](../maintainers/testing-guide.md) - Comprehensive testing strategy
- [Test Coverage](../maintainers/test-coverage.md) - Current coverage metrics
- [Acceptance Tests](../maintainers/acceptance-tests.md) - Manual test procedures
