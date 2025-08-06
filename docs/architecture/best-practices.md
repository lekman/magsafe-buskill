# Best Practices for Structuring Swift Projects with Business Logic Separation

## Modern Architecture Patterns Drive Swift Project Structure

The Swift development landscape in 2024 emphasizes clear separation between business logic and application code through sophisticated architecture patterns and modular design. Based on extensive research from major tech companies, conference talks, and community best practices, four primary architecture patterns dominate modern Swift development: Clean Architecture, VIPER, MVVM-C, and The Composable Architecture (TCA).

**Clean Architecture** has emerged as the most versatile pattern for complex business requirements. It enforces separation through distinct layers - Use Cases contain business logic independent of UI, Entities represent core business objects, and Repositories abstract data access. For a comprehensive implementation guide with MagSafe Guard examples, see [Clean Architecture Patterns](clean-architecture-patterns.md). A typical implementation separates concerns through protocol boundaries:

```swift
// Use Case - Pure business logic
protocol EmployeesRepository {
    func fetchEmployees(completion: @escaping (Result<[Employee], Error>) -> Void)
}

class FetchEmployeeListUseCase {
    private let repository: EmployeesRepository

    init(repository: EmployeesRepository) {
        self.repository = repository
    }

    func execute(completion: @escaping (Result<[Employee], Error>) -> Void) {
        repository.fetchEmployees(completion: completion)
    }
}
```

**VIPER** provides maximum separation but requires significant investment. Uber's adoption of VIPER principles through their RIBs (Router-Interactor-Builder) architecture demonstrates its effectiveness at scale, supporting 40+ teams working in parallel. The pattern divides logic into five components with clear responsibilities, though it generates substantial boilerplate - typically 4-5 files per feature.

**MVVM-C** offers the best balance for SwiftUI applications, combining MVVM's data binding strengths with the Coordinator pattern's navigation management. This pattern has gained significant traction due to its seamless integration with SwiftUI and Combine, making it ideal for reactive programming approaches.

**TCA** excels at complex state management through unidirectional data flow. Point-Free's framework has accumulated 12,000+ GitHub stars and provides excellent testability through pure functions, though it requires functional programming expertise.

## Feature-based folder structure replaces traditional MVC organization

The most significant shift in Swift project organization is the move from traditional MVC folders to **feature-based structure**. This approach, adopted by major companies including Airbnb and Square, groups related functionality together rather than separating by technical layers.

```ini
MyApp/
├── Features/
│   ├── Authentication/
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   └── LoginCredentials.swift
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   └── SignUpView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthenticationViewModel.swift
│   │   ├── Services/
│   │   │   └── AuthenticationService.swift
│   │   └── Protocols/
│   │       └── AuthenticationServiceProtocol.swift
│   ├── Dashboard/
│   └── Profile/
├── Shared/
│   ├── Networking/
│   ├── Extensions/
│   └── Utilities/
└── Resources/
```

This structure provides several advantages: reduced merge conflicts when teams work on different features, easier navigation through related code, and natural boundaries for modularization. The key principle is keeping entry points (AppDelegate, SceneDelegate) at the top level while grouping by business domain first, technical layers second.

## Protocol placement follows proximity principle

Modern Swift projects follow the **proximity principle** for protocol organization - protocols should be placed close to their primary usage. For simple protocols, place them in the same file as their primary implementation:

```swift
// UserService.swift
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

class UserService: UserServiceProtocol {
    // Implementation
}
```

For complex or widely-shared protocols, create dedicated protocol files within feature folders. Delegates follow a similar pattern - use separate extensions in the same file for simple cases:

```swift
// ProfileViewController.swift
class ProfileViewController: UIViewController {
    // Main implementation
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    // TableView data source methods
}
```

For protocol-oriented design, establish a clear hierarchy:

```ini
Core/
├── Protocols/
│   ├── DataSource.swift
│   ├── Configurable.swift
│   └── Cacheable.swift
├── Default Implementations/
│   └── DataSource+Defaults.swift
└── Extensions/
    └── Collection+DataSource.swift
```

## File organization follows the "Rule of Threes"

Swift by Sundell's "Rule of Threes" provides practical guidance: when you have three or more related components, group them together. Files should remain under 500 lines (ideally 200-300), with single responsibility per file. Avoid generic "dumping ground" folders like `Utilities/` or `Helpers/` - instead use specific, descriptive names like `NetworkingUtilities.swift` or `DateFormatting.swift`.

File naming conventions follow clear patterns:

- `MyType.swift` - Single type definition
- `MyType+MyProtocol.swift` - Extension adding protocol conformance
- `String+Validation.swift` - Functionality-specific extensions

## Testing architecture separates business logic from UI concerns

Modern Swift testing architecture emphasizes clear separation between business logic tests and UI tests. The recommended folder structure mirrors the main code organization:

```ini
Tests/
├── UnitTests/
│   ├── AuthenticationTests/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── ViewModels/
│   └── TestHelpers/
│       ├── Mocks/
│       └── TestData/
├── IntegrationTests/
└── UITests/
```

Apple's new **Swift Testing framework** (introduced at WWDC 2024) provides significant improvements over XCTest:

```swift
import Testing

@Test("User validation with valid data")
func userValidation() {
    let user = User(name: "John", email: "john@example.com")
    #expect(user.isValid == true)
}

@Test("User validation", arguments: [
    ("", "john@example.com", false),
    ("John", "", false),
    ("John", "john@example.com", true)
])
func userValidationParameterized(name: String, email: String, expected: Bool) {
    let user = User(name: name, email: email)
    #expect(user.isValid == expected)
}
```

## Protocol-oriented design enables proper separation of concerns

Protocol-oriented programming remains fundamental to Swift architecture. It enables dependency injection, improves testability, and enforces clear boundaries between components:

```swift
// Define protocols for core functionality
protocol NetworkService {
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

protocol CacheService {
    func store<T: Codable>(_ object: T, forKey key: String)
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T?
}

// Implement services with clear dependencies
class UserService {
    private let networkService: NetworkService
    private let cacheService: CacheService

    init(networkService: NetworkService, cacheService: CacheService) {
        self.networkService = networkService
        self.cacheService = cacheService
    }
}
```

## Industry leaders shape architectural decisions

**Meta's Facebook iOS app** demonstrates extreme modularization with custom ComponentKit framework, dynamic libraries for startup performance, and a plugin system with Buck-powered code generation. While complex, it supports hundreds of engineers working simultaneously.

**Uber's RIBs architecture** provides business-driven (not view-driven) structure with hierarchical dependency injection and cross-platform consistency between iOS and Android. Their approach emphasizes reactive programming with RxSwift/Combine.

**Square's Ziggurat architecture** implements layered design with one-way data flow, using immutable view models for compile-time safety and clear separation between business logic, presentation, and UI layers.

## Dependency injection evolves beyond constructor patterns

Modern Swift projects employ sophisticated dependency injection patterns. Property wrapper-based injection has become the 2024 best practice:

```swift
@propertyWrapper
struct Injected<T> {
    private let keyPath: WritableKeyPath<InjectedValues, T>

    var wrappedValue: T {
        get { InjectedValues[keyPath] }
        set { InjectedValues[keyPath] = newValue }
    }

    init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}

// Usage
class UserViewModel {
    @Injected(\.userService) var userService: UserServiceProtocol
    @Injected(\.analytics) var analytics: AnalyticsProtocol
}
```

For smaller projects, manual dependency injection remains effective:

```swift
protocol Injectable {
    var userService: UserServiceProtocol { get }
    var analytics: AnalyticsProtocol { get }
}

class DependencyContainer: Injectable {
    lazy var userService: UserServiceProtocol = UserService()
    lazy var analytics: AnalyticsProtocol = AnalyticsService()
}
```

## Swift Package Manager drives modularization and testability

SPM has become the default choice for modularization in 2024. Companies use SPM modules for feature boundaries, reusable components, team boundaries, and platform sharing. The decision matrix for using SPM modules versus folders considers team ownership, compile dependencies, reusability needs, and build time impact.

### Separation of Business Logic from Platform Code

Modern Swift applications achieve 100% testable business logic by separating code into two distinct layers:

#### Swift Package Manager (Business Logic Layer)

- Contains all business logic, domain models, and use cases
- Pure Swift code with no platform dependencies
- 100% unit testable without UI or system mocks
- Can be tested on Linux CI/CD pipelines
- Shareable across iOS, macOS, watchOS, tvOS platforms

#### Xcode Project (Platform/Infrastructure Layer)

- Contains UI components (SwiftUI/UIKit views)
- Platform-specific implementations (notifications, keychain, file system)
- System event handlers and delegates
- Third-party SDK integrations
- Thin adapters that bridge SPM protocols to platform APIs

### Example: MagSafe Guard Architecture

A real-world example demonstrates this separation. For detailed Clean Architecture implementation in this project, see [Clean Architecture Patterns](clean-architecture-patterns.md):

```ini
MagSafeGuard/                    # Xcode Project (Platform Layer)
├── MagSafeGuard/
│   ├── UI/                      # SwiftUI Views
│   │   ├── MenuBarView.swift
│   │   └── SettingsView.swift
│   ├── Services/                # Platform Services
│   │   ├── MacSystemActions.swift       # macOS-specific APIs
│   │   └── PowerMonitorService.swift    # IOKit integration
│   ├── Security/                # Infrastructure
│   │   ├── RateLimiter.swift           # Concrete implementation
│   │   ├── CircuitBreaker.swift        # Concrete implementation
│   │   └── ResourceProtectionPolicyAdapter.swift  # Adapter pattern
│   └── Data/
│       └── Repositories/
│           └── MacSystemActionsRepository.swift  # System integration
│
MagSafeGuardLib/                 # Swift Package (Business Logic)
├── Sources/
│   └── MagSafeGuardDomain/
│       ├── Protocols/           # Pure abstractions
│       │   ├── SecurityActionRepository.swift
│       │   └── ResourceProtectionProtocols.swift
│       ├── UseCases/            # Business logic
│       │   ├── ProtectedActionUseCase.swift
│       │   └── PowerMonitoringUseCase.swift
│       ├── Models/              # Domain models
│       │   ├── SecurityAction.swift
│       │   └── PowerState.swift
│       └── ValueObjects/        # Pure data
│           └── Configuration.swift
└── Tests/
    ├── MagSafeGuardDomainTests/
    │   └── UseCases/            # 100% coverage achievable
    └── TestInfrastructure/
        └── Mocks/               # Pure Swift mocks
```

### Benefits of SPM/Xcode Separation

#### Testability Benefits

- Business logic tested without UI automation
- No need for XCUITest for core functionality
- Tests run faster (milliseconds vs seconds)
- Can achieve 100% code coverage on business logic
- Tests are deterministic and reproducible

#### Architecture Benefits

- Clear separation of concerns
- Platform-agnostic business rules
- Easier onboarding (business logic has no platform complexity)
- Reduced cognitive load per module
- Natural dependency boundaries

#### Development Benefits

- Parallel development (teams can work on SPM packages independently)
- Faster compile times (incremental compilation of packages)
- Easier code review (clear boundaries)
- Simplified debugging (isolated components)
- Better IDE performance (smaller compilation units)

### Implementation Strategy

#### Phase 1: Identify Core Business Logic

```swift
// Before: Mixed in Xcode project
class UserViewController: UIViewController {
    func validateUser(_ user: User) -> Bool {
        // Business logic mixed with UI
        return user.age >= 18 && user.email.contains("@")
    }
}

// After: In SPM package
public struct UserValidator {
    public func validate(_ user: User) -> ValidationResult {
        // Pure business logic
        let errors = [
            user.age < 18 ? .underage : nil,
            !user.email.contains("@") ? .invalidEmail : nil
        ].compactMap { $0 }

        return errors.isEmpty ? .valid : .invalid(errors)
    }
}
```

#### Phase 2: Create Protocol Boundaries

```swift
// In SPM Package
public protocol NotificationService {
    func schedule(_ notification: DomainNotification) async throws
}

// In Xcode Project
import UserNotifications

class IOSNotificationService: NotificationService {
    func schedule(_ notification: DomainNotification) async throws {
        // Platform-specific implementation
        let content = UNMutableNotificationContent()
        content.title = notification.title
        // ... iOS specific code
    }
}
```

#### Phase 3: Inject Dependencies

```swift
// In SPM Package - Pure business logic
public class ReminderUseCase {
    private let validator: ReminderValidator
    private let repository: ReminderRepository
    private let notifications: NotificationService

    public init(
        validator: ReminderValidator,
        repository: ReminderRepository,
        notifications: NotificationService
    ) {
        self.validator = validator
        self.repository = repository
        self.notifications = notifications
    }

    public func scheduleReminder(_ reminder: Reminder) async throws {
        try validator.validate(reminder)
        try await repository.save(reminder)
        try await notifications.schedule(reminder.notification)
    }
}
```

### Testing Strategy Comparison

#### SPM Package Tests (Fast, Deterministic)

```swift
@Test("Reminder scheduling with valid data")
func testReminderScheduling() async throws {
    // Given - Pure Swift mocks
    let mockRepo = MockReminderRepository()
    let mockNotifications = MockNotificationService()
    let useCase = ReminderUseCase(
        validator: ReminderValidator(),
        repository: mockRepo,
        notifications: mockNotifications
    )

    // When
    let reminder = Reminder(title: "Test", date: .now)
    try await useCase.scheduleReminder(reminder)

    // Then - Instant verification
    #expect(mockRepo.savedReminders.contains(reminder))
    #expect(mockNotifications.scheduledCount == 1)
}
```

#### Xcode Project Tests (Platform Integration)

```swift
func testNotificationPermissions() async throws {
    // Only test the thin platform layer
    let service = IOSNotificationService()
    let status = await service.requestAuthorization()
    XCTAssertNotNil(status)
}
```

### Migration Path for Existing Projects

1. **Audit Current Code** - Identify business logic in ViewControllers/Views
2. **Create SPM Package** - Start with core domain models
3. **Extract Use Cases** - Move business operations to use cases
4. **Define Protocols** - Create boundaries for platform dependencies
5. **Implement Adapters** - Bridge SPM protocols to platform code
6. **Migrate Tests** - Convert XCTest to Swift Testing in SPM
7. **Measure Coverage** - Aim for 100% on SPM, 60-80% on platform layer

A typical modular structure:

```ini
MyApp/
├── Packages/
│   ├── Core/           // Shared utilities (100% tested)
│   ├── Domain/         // Business logic (100% tested)
│   ├── Networking/     // API layer with protocols
│   ├── FeatureHome/    // Home feature logic
│   ├── FeatureProfile/ // Profile feature logic
│   └── DesignSystem/   // Reusable UI components
└── MyApp/              // Main app target (integration)

## Key architectural recommendations for 2024-2025

For new projects, start with **MVVM-C** for SwiftUI applications, especially with iOS 16+ targets. Consider **Clean Architecture** with Swift Package Manager modularity for large enterprise apps. Choose **TCA** if your team has functional programming experience and complex state management needs. Reserve **VIPER** for highly modular requirements where maximum separation justifies development overhead.

Modern Swift considerations include full async/await support across all patterns, with MVVM-C and TCA providing the best native SwiftUI integration. Clean Architecture and TCA offer the most comprehensive testing capabilities, while MVVM-C provides the gentlest learning curve for most iOS developers.

The trend shows increasing adoption of MVVM-C for new SwiftUI projects, continued use of Clean Architecture in enterprise environments, and growing traction for TCA among teams dealing with complex application state. Feature-based organization, protocol-oriented design, and Swift Package Manager modularization have become industry standards, with automated tooling ensuring consistency at scale.
```
