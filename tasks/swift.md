# Swift Tasks

This module provides Swift development tasks including building, testing, linting, and code coverage.

## Available Tasks

```bash
task swift:              # Show available Swift tasks
task swift:build         # Build the project
task swift:test          # Run Swift tests
task swift:test:coverage # Run tests with coverage report
task swift:test:html     # Generate HTML coverage report
task swift:lint          # Run SwiftLint
task swift:lint:fix      # Auto-fix SwiftLint issues
task swift:clean         # Clean build artifacts
task swift:docs          # Generate API documentation
task swift:sbom          # Generate Software Bill of Materials
```

## Task Details

### Building (`task swift:build`)

Builds the project in release mode:

- Optimized for performance
- Creates `.build/release/` artifacts
- Used by `task run` command

### Testing (`task swift:test`)

Runs the test suite with parallel execution:

- Uses `--parallel --num-workers 1` to avoid hanging issues
- Captures output for analysis
- Reports pass/fail status

### Test Coverage (`task swift:test:coverage`)

Runs tests with code coverage analysis:

- Generates coverage reports
- Enforces 80% minimum coverage
- Shows uncovered files
- Excludes test files and UI code

**Coverage exclusions:**

- `*Tests.swift`
- `Mock*.swift`
- `MagSafeGuardApp.swift`
- `PowerMonitorService.swift`
- `*LAContext*.swift`
- `MacSystemActions.swift`
- `*Protocol.swift`

**Output formats:**

- Console report with percentages
- `coverage.xml` for SonarCloud
- `coverage.lcov` for Codecov

### HTML Coverage Report (`task swift:test:html`)

Generates visual coverage report:

- Creates `coverage.html`
- Opens in default browser
- Shows line-by-line coverage
- Interactive navigation

### Linting (`task swift:lint`)

Runs SwiftLint to check code style:

- Uses `.swiftlint.yml` configuration
- Reports warnings and errors
- Integrated with git hooks

### Auto-fix Linting (`task swift:lint:fix`)

Automatically fixes SwiftLint issues:

- Corrects formatting
- Applies safe fixes only
- Run before committing

### Clean Build (`task swift:clean`)

Removes build artifacts:

- Deletes `.build/` directory
- Cleans SPM cache
- Frees disk space

### API Documentation (`task swift:docs`)

Generates API documentation using Swift-DocC:

- Uses Apple's official documentation compiler
- Creates static website for hosting
- Supports custom output directory
- Includes all public APIs

**Usage:**

```bash
# Generate to default location (docs/api)
task swift:docs

# Generate to custom location
task swift:docs OUTPUT_PATH=./build/docs

# Preview with live reload
swift package --disable-sandbox preview-documentation --target MagSafeGuard
```

**Requirements:**

- Swift 5.5 or later
- Documentation comments using `///` or `/** */`

### SBOM Generation (`task swift:sbom`)

Creates Software Bill of Materials:

- SPDX format
- Lists all dependencies
- Includes versions and licenses
- Output: `sbom.spdx`

## Configuration

### SwiftLint Rules

Configure in `.swiftlint.yml`:

```yaml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - closure_spacing

excluded:
  - .build
  - Tests
```

### Coverage Thresholds

Modify in `swift.yml`:

```yaml
vars:
  MIN_COVERAGE: "80"  # Minimum required coverage
```

## Development Workflow

### Standard Development Cycle

1. Make code changes
2. Run tests: `task swift:test`
3. Check coverage: `task swift:test:coverage`
4. Fix linting: `task swift:lint:fix`
5. Build release: `task swift:build`

### Before Committing

```bash
# Quick validation
task swift:lint
task swift:test

# Or use the combined command
task qa:quick
```

### Before Pull Request

```bash
# Comprehensive check
task swift:test:coverage
task swift:lint
task swift:sbom

# Or use the combined command
task qa
```

## Troubleshooting

### Tests Hanging

If tests hang or timeout:

1. We use `--parallel --num-workers 1` by default
2. Check for UI operations in tests
3. Ensure proper test isolation

### Coverage Not Generated

If coverage files are missing:

1. Ensure tests pass first
2. Check for `.profdata` files in `.build`
3. Verify executable path is correct

### SwiftLint Not Found

Install SwiftLint:

```bash
brew install swiftlint
```

### Build Failures

Common solutions:

1. Clean build: `task swift:clean`
2. Update packages: `swift package update`
3. Reset package cache: `swift package reset`

## CI/CD Integration

Swift tasks in GitHub Actions:

- Pull requests run: `swift:test`, `swift:lint`
- Coverage uploaded to Codecov
- SBOM generated for releases

## Performance Tips

### Faster Builds

- Use `swift build` for debug builds
- Use `task swift:build` for optimized builds
- Enable build caching in CI

### Faster Tests

- Run specific tests: `swift test --filter TestName`
- Use focused testing during development
- Run full suite before committing

## Best Practices

1. **Maintain test coverage** above 80%
2. **Fix linting issues** before committing
3. **Update SBOM** after dependency changes
4. **Clean builds** when switching branches
5. **Run full test suite** before pushing
