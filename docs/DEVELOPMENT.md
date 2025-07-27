# Development Guide

This guide explains how to set up your development environment and follow coding standards for MagSafe Guard.

## Quick Start

```bash
# Complete development setup
task dev:setup

# Check that everything works
task test
task lint
```

## Development Standards

### Code Quality Tools

We use several tools to maintain code quality:

- **SwiftLint**: Enforces Swift coding conventions and style
- **SonarCloud**: Static code analysis and quality gates
- **Markdownlint**: Documentation formatting
- **Semgrep**: Security scanning

### SwiftLint Configuration

SwiftLint is configured in `.swiftlint.yml` with rules focused on:

#### Documentation Requirements

- **missing_docs**: All public APIs must have documentation
- **file_header**: Consistent file headers required
- **explicit_type_interface**: Public APIs need explicit types

#### Code Quality

- **explicit_acl**: Clear access control levels
- **redundant_type_annotation**: Remove unnecessary type annotations
- **sorted_imports**: Keep imports organized
- **unused_import**: Remove unused imports

#### Security

- **no_print_statements**: Use proper logging instead of print
- **security_todo**: Security TODOs are treated as errors

### Running Linting

```bash
# Check all linting issues
task lint

# Fix auto-fixable issues
task lint:fix

# Swift-specific linting
task lint:swift
task lint:fix:swift

# Markdown linting
task lint:markdown
task lint:fix:markdown
```

### Documentation Standards

#### Swift Documentation

All public APIs must have comprehensive documentation using Swift DocC format:

````swift
/// Brief description of the class/function.
///
/// Detailed description explaining the purpose, behavior, and usage.
/// Can include multiple paragraphs and examples.
///
/// ## Usage
///
/// ```swift
/// let controller = AppController()
/// controller.arm { result in
///     // Handle result
/// }
/// ```
///
/// ## Thread Safety
///
/// Explain thread safety guarantees.
///
/// - Parameters:
///   - parameter1: Description of first parameter
///   - parameter2: Description of second parameter
/// - Returns: Description of return value
/// - Throws: Description of possible errors
/// - Note: Additional important information
/// - Warning: Critical warnings about usage
public class AppController {
    /// Property description with behavior details
    @Published public private(set) var currentState: AppState = .disarmed
}
````

#### Required Documentation Elements

1. **Public Classes/Structs/Enums**:

   - Purpose and responsibility
   - Usage examples
   - Thread safety notes
   - State management (if applicable)

2. **Public Methods**:

   - What the method does
   - Parameter descriptions
   - Return value description
   - Possible errors/exceptions
   - Side effects

3. **Public Properties**:

   - What the property represents
   - When it changes
   - Thread safety

4. **Enums**:
   - Each case should be documented
   - State transitions (for state enums)

### Testing Standards

#### Test Coverage Requirements

- **Minimum 80% code coverage** for production code
- UI components and system integrations are excluded from coverage requirements
- Test files, mocks, and protocols don't count toward coverage

#### Running Tests

```bash
# Run all tests
task test

# Run with coverage reporting
task test:coverage

# Generate HTML coverage report
task test:coverage:html
```

#### What to Test

1. **Unit Tests**: All business logic, state management, data processing
2. **Integration Tests**: Service interactions, authentication flows
3. **Error Handling**: All error paths and edge cases
4. **State Transitions**: AppController state machine
5. **Configuration**: Settings validation and persistence

#### What NOT to Test

- UI components (SwiftUI views) - use UI testing frameworks instead
- System integration points (IOKit, LocalAuthentication) - use mocks
- Third-party libraries
- Generated code

### Security Standards

#### Security Scanning

```bash
# Run all security checks
task test:security

# Full security audit
task security
```

#### Security Requirements

1. **No Hardcoded Secrets**: All API keys, passwords, tokens in environment variables
2. **Input Validation**: Validate all user inputs and external data
3. **Authentication**: All security operations require user authentication
4. **Secure Storage**: Use Keychain for sensitive data
5. **Principle of Least Privilege**: Minimal required permissions

#### GitHub Actions Security

- All GitHub Actions must be pinned to specific commit SHAs
- Use `task security:pin-actions` to pin actions automatically
- Dependabot keeps actions updated weekly

### Code Style

#### Swift Style Guidelines

Following Swift API Design Guidelines with project-specific additions:

1. **Naming**:

   - Clear, descriptive names
   - Avoid abbreviations
   - Use `get`/`set` prefixes sparingly

2. **Access Control**:

   - Default to `internal`
   - Mark `public` only what needs to be exposed
   - Use `private(set)` for read-only properties

3. **Error Handling**:

   - Use Swift's error handling (`throws`)
   - Create meaningful error types
   - Log errors appropriately

4. **Async/Await**:
   - Prefer async/await over callbacks where possible
   - Mark async functions clearly
   - Handle cancellation properly

#### File Organization

```ini
Sources/MagSafeGuard/
├── AppController.swift          # Main controller
├── AppDelegateCore.swift       # App lifecycle
├── MagSafeGuardApp.swift       # App entry point
├── NotificationService.swift    # Notifications
├── Services/                   # Business logic services
│   ├── AuthenticationService.swift
│   ├── PowerMonitorService.swift
│   └── SecurityActionsService.swift
├── Settings/                   # Configuration
│   ├── SettingsModel.swift
│   ├── SettingsView.swift
│   └── UserDefaultsManager.swift
└── Views/                     # UI components
    └── PowerMonitorDemoView.swift
```

### Pre-commit Workflow

Git hooks automatically run these checks:

1. **Secret Scanning**: Prevent committing secrets
2. **Security Scan**: Semgrep static analysis
3. **Commit Message**: Conventional commit format validation

#### Conventional Commits

Use this format for all commits:

```text
type(scope): description

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Code style/formatting
- refactor: Code refactoring
- test: Tests
- chore: Maintenance

Examples:
- feat(auth): add TouchID authentication
- fix(power): resolve monitoring memory leak
- docs(api): update controller documentation
```

### Continuous Integration

#### GitHub Workflows

1. **Test Workflow**: Runs on all PRs and pushes

   - Unit tests with coverage
   - Security scanning
   - Linting
   - SonarCloud analysis

2. **Security Workflow**: Weekly security scans
   - Dependency scanning
   - Action pin verification
   - Secret scanning

#### Quality Gates

PRs must pass:

- All tests (100% pass rate)
- Security scan (no high/critical issues)
- Code coverage (>80% for production code)
- SonarCloud quality gate
- SwiftLint (no errors)

### Development Workflow

#### Setting Up

```bash
# Clone repository
git clone https://github.com/lekman/magsafe-buskill.git
cd magsafe-buskill

# Set up development environment
task dev:setup
```

#### Daily Development

```bash
# Start working on feature
git checkout -b feature/new-feature

# Make changes, then before committing:
task lint:fix           # Fix auto-fixable issues
task test              # Run all tests
task pre-commit        # Final checks

# Interactive commit with conventional format
task commit

# Before pushing
task pre-push          # Complete pre-push checks
git push origin feature/new-feature
```

#### Pre-PR Checklist

```bash
# Run comprehensive checks
task pre-pr

# Ensure documentation is complete
task lint:swift        # Check for missing docs
```

### Tools Installation

#### macOS (Recommended)

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all development tools
task dev:setup
```

#### Manual Installation

```bash
# SwiftLint
brew install swiftlint

# Semgrep
brew install semgrep

# Markdownlint
npm install -g markdownlint-cli
# or
brew install markdownlint-cli

# jq (for SBOM generation)
brew install jq

# Task runner
brew install go-task/tap/go-task
```

### Troubleshooting

#### Common Issues

1. **SwiftLint not found**:

   ```bash
   brew install swiftlint
   ```

2. **Tests failing locally**:

   ```bash
   task clean
   task test
   ```

3. **Coverage calculation issues**:

   ```bash
   rm -rf .build
   task test:coverage
   ```

4. **Git hooks not working**:

   ```bash
   task setup-hooks
   chmod +x .githooks/*
   ```

#### Getting Help

1. Check existing issues on GitHub
2. Run `task --list` to see all available commands
3. Check tool versions: `swift --version`, `swiftlint version`
4. Review CI logs for detailed error information

### Performance Guidelines

#### Code Performance

- Use `@MainActor` for UI updates
- Prefer value types (structs) for data models
- Minimize memory allocations in hot paths
- Profile with Instruments when needed

#### Build Performance

- Keep dependency count low
- Use `@_spi` for internal APIs
- Minimize compilation time with modular architecture

### Accessibility

- All UI must support VoiceOver
- Use semantic UI elements
- Provide alternative text for images
- Test with accessibility inspector

---

## Quick Reference

### Essential Commands

```bash
task dev:setup        # Complete development setup
task test             # Run all tests
task lint             # Check code quality
task lint:fix         # Fix auto-fixable issues
task pre-push         # Pre-push checks
task security         # Security audit
task run              # Build and run app
```

### Documentation Commands

```bash
task docs:update      # Update documentation
task test:coverage    # Generate coverage report
task swift:sbom       # Generate software bill of materials
```

### Security Commands

```bash
task security:pin-actions    # Pin GitHub Actions
task security:scan-secrets   # Scan for secrets
task security:check-pins     # Verify action pins
```

This development guide ensures consistent, high-quality, secure code across the MagSafe Guard project.
