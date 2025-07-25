# Test Coverage Report

This document tracks the current test coverage status for MagSafe Guard. For information about the testing strategy and architecture, see the [Testing Guide](testing-guide.md).

## Current Coverage Status

As of the latest test run:

- **Overall Coverage**: 81.51% ✅ (exceeds 80% target)
- **Line Coverage**: 81.51% (767/941 lines)
- **Function Coverage**: 91.18% (93/102 functions)

### Coverage by File

| File | Coverage | Status | Notes |
|------|----------|--------|---------|
| AppDelegateCore | 94.44% | ✅ | Core business logic fully tested |
| AuthenticationService | 95.43% | ✅ | Comprehensive mock-based tests |
| SecurityActionsService | 69.70% | ⚠️ | Limited by system action mocking |
| PowerMonitorDemoView | 87.02% | ✅ | View model well tested |
| PowerMonitorService | Excluded | - | IOKit-specific code |
| PowerMonitorCore | Excluded | - | Coverage tool issue |
| MagSafeGuardApp | Excluded | - | NSApp-dependent UI code |

## Coverage Trends

| Date | Overall | Line | Function | Notes |
|------|---------|------|----------|---------|
| 2025-07-25 | 81.51% | 81.51% | 91.18% | Protocol refactoring complete |
| 2025-07-24 | 75.20% | 75.20% | 85.00% | Initial coverage baseline |

## Coverage Details

### High Coverage Files (>90%)

#### AuthenticationService.swift (95.43%)

- Comprehensive mock-based testing
- All authentication flows covered
- Rate limiting and error handling tested

#### AppDelegateCore.swift (94.44%)

- Business logic extracted from UI
- Menu creation and state management tested
- Power monitoring integration covered

### Medium Coverage Files (70-90%)

#### PowerMonitorDemoView.swift (87.02%)

- View model functionality tested
- Monitoring state changes covered
- Minor gaps in SwiftUI lifecycle

#### SecurityActionsService.swift (69.70%)

- Configuration and persistence tested
- System actions mocked for safety
- Lower coverage due to system integration points

### Excluded Files

Files excluded from coverage with rationale:

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

## Running Coverage Reports

### Quick Commands

```bash
# Generate coverage report
task test:coverage

# View HTML coverage report
task test:coverage:html
open .build/coverage/index.html

# CI environment
CI=true task test:coverage
```

### Manual Coverage Generation

```bash
# 1. Run tests with coverage enabled
swift test --enable-code-coverage

# 2. Generate profdata
xcrun llvm-profdata merge -sparse \
  .build/*/debug/codecov/*.profraw \
  -o .build/*/debug/codecov/default.profdata

# 3. Generate report
xcrun llvm-cov report \
  .build/*/debug/MagSafeGuardPackageTests.xctest/Contents/MacOS/MagSafeGuardPackageTests \
  -instr-profile=.build/*/debug/codecov/default.profdata \
  -ignore-filename-regex=".*Tests\.swift|.*Mock.*\.swift|.*/runner.swift"
```

## CI/CD Integration

### GitHub Actions

Coverage is automatically generated in CI:

```yaml
- name: Run Tests with Coverage
  env:
    CI: true
  run: task test:coverage
```

### SonarCloud

Coverage reports are converted to SonarQube format:

```bash
task test:convert  # Converts LCOV to SonarQube XML
```

### Codecov

Coverage is uploaded to Codecov for tracking:

```bash
bash <(curl -s https://codecov.io/bash)
```

## Coverage Goals

- **Target**: 80% overall coverage
- **Current**: 81.51% ✅
- **Strategy**: Protocol-based testing for business logic
- **Exclusions**: UI and system integration code

For details on improving coverage, see the [Testing Guide](testing-guide.md).
