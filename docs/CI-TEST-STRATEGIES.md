# CI Test Strategies

This document describes two approaches for running tests in CI without triggering system permission dialogs.

## Problem

When running tests in GitHub Actions on macOS runners, the app may trigger system permission dialogs for:
- Location services
- Accessibility permissions
- Other system services

These dialogs cause tests to hang indefinitely in CI.

## Solution 1: CI-Specific Test Configuration (Primary)

Uses a custom test scheme and configuration to run tests without launching the app.

### Usage

```bash
# In CI (automated)
task test-ci:coverage

# Local testing with CI config
task test-ci:unit
```

### How it works

1. **Custom Scheme**: `MagSafeGuardUnitTests.xcscheme` configured to:
   - Only build test targets
   - Skip app launch
   - Set environment variables (CI=true, MAGSAFE_GUARD_TEST_MODE=1)

2. **Build Configuration**: Uses `xcodebuild` with:
   - `TEST_HOST=` and `BUNDLE_LOADER=` (empty to prevent app hosting)
   - Code signing disabled
   - Sandbox and hardened runtime disabled
   - Only unit tests included (`-only-testing`, `-skip-testing`)

3. **Two-phase execution**:
   - `build-for-testing`: Builds test bundle without app
   - `test-without-building`: Runs tests from built bundle

## Solution 2: Local Coverage Generation (Alternative)

Generate coverage locally and commit the results for CI to use.

### Usage

```bash
# Generate coverage locally
task test-local:coverage

# Generate and commit coverage
task test-local:coverage:commit

# Push to trigger CI with cached coverage
git push
```

### How it works

1. **Local Generation**: Run tests locally where permission dialogs can be handled
2. **Commit Coverage**: Check in `coverage.lcov` and `coverage.xml`
3. **CI Upload**: Separate workflow uploads pre-generated coverage to Codecov/SonarCloud

### Advantages
- No permission issues in CI
- Faster CI runs (no test execution)
- Consistent coverage across environments

### Disadvantages
- Coverage files in git history
- Manual step required before push
- Coverage may be out of sync with code

## Choosing an Approach

Use **Solution 1** (CI-specific config) when:
- You want fully automated CI
- Tests can run without system services
- All dependencies are properly mocked

Use **Solution 2** (local coverage) when:
- Tests require actual system services
- CI environment is too restrictive
- You need consistent coverage metrics

## Implementation Details

### Environment Variables

Both approaches use these environment variables:
- `CI=true`: Indicates CI environment
- `MAGSAFE_GUARD_TEST_MODE=1`: Disables system integrations in app code

### Coverage Generation

Coverage is generated using:
```bash
xcrun llvm-cov export \
  -format=lcov \
  -instr-profile="Coverage.profdata" \
  "MagSafeGuardTests" \
  > coverage.lcov
```

### Files Modified

1. **CI Test Configuration**:
   - `/tasks/test-ci.yml`: CI-specific test tasks
   - `/MagSafeGuard.xcodeproj/xcshareddata/xcschemes/MagSafeGuardUnitTests.xcscheme`: Unit test scheme
   - `/.github/workflows/test.yml`: Uses `task test-ci:coverage`

2. **Local Coverage**:
   - `/tasks/test-local.yml`: Local test tasks
   - `/.github/workflows/test-cached.yml`: Upload cached coverage
   - `/.gitignore`: Modified to allow coverage.lcov and coverage.xml

## Troubleshooting

### Tests still hanging in CI?

1. Check test logs for permission requests
2. Ensure all location/system service code is properly mocked
3. Verify `MAGSAFE_GUARD_TEST_MODE` is respected in app code
4. Consider using Solution 2 (local coverage)

### Coverage not generating?

1. Ensure tests actually run (check for early exits)
2. Verify binary and profdata paths are correct
3. Check that `-enableCodeCoverage YES` is set
4. Run with `-verbose` flag for debugging

### Wrong coverage reported?

1. Clean derived data before running tests
2. Ensure correct test binary is used for coverage
3. Check that UI tests are properly excluded
4. Verify source file paths are correct