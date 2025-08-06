# SPM Separation Guide: MagSafeGuard Security Components

## Overview

This guide clarifies which components belong in MagSafeGuardLib (Swift Package) versus MagSafeGuard (Xcode project) based on Clean Architecture principles.

## Current Security Folder Analysis

### What Should Stay in MagSafeGuard (Infrastructure)

All files currently in `MagSafeGuard/Security/` should **remain** as infrastructure:

| File | Purpose | Why Infrastructure |
|------|---------|-------------------|
| `RateLimiter.swift` | Token bucket implementation | Actor-based concurrency, technical algorithm |
| `CircuitBreaker.swift` | Circuit breaker state machine | Actor implementation, state management |
| `ResourceProtector.swift` | Coordination of protection mechanisms | Infrastructure orchestration |
| `ResourceProtectionPolicyAdapter.swift` | Adapter to domain protocol | Bridge pattern implementation |

These contain:

- **Actor-based concurrency** (platform-specific Swift feature)
- **Technical algorithms** (token bucket, circuit state machines)
- **Infrastructure coordination** (orchestrating multiple protection mechanisms)
- **Adapter implementations** (bridging infrastructure to domain)

### What's Already in MagSafeGuardLib (Domain)

Located in `MagSafeGuardLib/Sources/MagSafeGuardDomain/`:

| Component | Location | Purpose |
|-----------|----------|---------|
| **Protocols** | `Protocols/ResourceProtectionProtocols.swift` | Domain abstractions |
| `ResourceProtectionPolicy` | | Business rule abstraction |
| `RateLimiterProtocol` | | Rate limiting contract |
| `CircuitBreakerProtocol` | | Circuit breaker contract |
| **Models** | | Domain data structures |
| `CircuitState` enum | | Domain state model |
| `ProtectionMetrics` | | Domain metrics |
| **Configuration** | | Business configuration |
| `RateLimiterConfig` | | Rate limit settings |
| `CircuitBreakerConfig` | | Circuit breaker settings |
| `ResourceProtectorConfig` | | Combined configuration |
| **Use Cases** | `UseCases/ProtectedActionUseCase.swift` | Business logic |
| `ProtectedActionUseCaseProtocol` | | Use case abstraction |
| `ProtectedActionUseCase` | | Business orchestration |
| `ProtectedSecurityAction` enum | | Domain actions |

## Clean Architecture Principles Applied

### 1. **Dependency Rule**

- Domain (MagSafeGuardLib) has **no dependencies** on infrastructure
- Infrastructure (MagSafeGuard) **depends on** domain protocols
- Dependencies point **inward** toward domain

### 2. **Abstraction vs Implementation**

- **MagSafeGuardLib**: Contains abstractions (protocols, interfaces)
- **MagSafeGuard**: Contains implementations (actors, algorithms)

### 3. **Business Logic vs Technical Details**

- **MagSafeGuardLib**: Business rules (when to protect, what to validate)
- **MagSafeGuard**: Technical details (how to implement protection)

## Decision Framework

### Move to MagSafeGuardLib When

✅ Pure business logic
✅ Domain models and entities
✅ Protocol definitions
✅ Use case orchestration
✅ Configuration as data
✅ No platform dependencies
✅ 100% unit testable

### Keep in MagSafeGuard When

✅ Actor implementations
✅ Technical algorithms
✅ Platform-specific code
✅ Framework integration
✅ External service calls
✅ Infrastructure coordination
✅ Adapter implementations

## Completed Refactoring

The following cleanup has been completed:

1. ✅ Removed duplicate `RateLimiterProtocol` from `RateLimiter.swift`
2. ✅ Removed duplicate `CircuitBreakerProtocol` and `CircuitState` from `CircuitBreaker.swift`
3. ✅ Removed duplicate `RateLimiterConfig` from `RateLimiter.swift`
4. ✅ Removed duplicate `CircuitBreakerConfig` from `CircuitBreaker.swift`
5. ✅ Removed duplicate `ResourceProtectorConfig` from `ResourceProtector.swift`
6. ✅ Added `import MagSafeGuardDomain` to all infrastructure files
7. ✅ Implemented missing `getRemainingTokens` method in `RateLimiter`

## Benefits Achieved

### 1. **Single Source of Truth**

- Protocols defined once in MagSafeGuardLib
- No duplicate definitions
- Clear ownership of abstractions

### 2. **100% Testable Business Logic**

- Use cases in MagSafeGuardLib tested without infrastructure
- Mock implementations for all protocols
- Fast, deterministic tests

### 3. **Platform Independence**

- Business logic can run on any Swift platform
- Infrastructure isolated to platform layer
- Easy to port to iOS, watchOS, etc.

### 4. **Clear Boundaries**

- Obvious what belongs where
- Reduced cognitive load
- Easier onboarding

## Future Considerations

### Potential Domain Additions

If these become needed, add to MagSafeGuardLib:

```swift
// Domain Services
public protocol SecurityValidationService {
    func validateScriptPath(_ path: String) -> Bool
    func validateActionPermissions(_ action: SecurityAction) -> Bool
}

// Domain Value Objects
public struct SecurityPolicy {
    let maxRetries: Int
    let timeoutDuration: TimeInterval
    let requiredPermissions: Set<Permission>
}

// Domain Events
public enum SecurityEvent {
    case actionBlocked(SecurityAction, reason: String)
    case rateLimitExceeded(action: SecurityAction)
    case circuitOpened(action: SecurityAction)
}
```

### Infrastructure Patterns

Keep these patterns in MagSafeGuard:

- **Repository Pattern**: Data access implementation
- **Adapter Pattern**: Bridge to domain protocols
- **Factory Pattern**: Creating infrastructure instances
- **Decorator Pattern**: Adding cross-cutting concerns

## Conclusion

The current separation is **correct**:

- All Security/ files are infrastructure and should stay in MagSafeGuard
- Domain abstractions are properly located in MagSafeGuardLib
- Clean Architecture principles are properly applied

No files need to be moved from MagSafeGuard/Security to MagSafeGuardLib.
