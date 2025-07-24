# Codecov Integration for Swift

## Overview

Codecov provides free code coverage reporting for open source Swift projects. This guide explains how to integrate Codecov with MagSafe Guard.

## Swift Support

Yes, **Codecov fully supports Swift**! It works with:
- Swift Package Manager projects
- Xcode projects
- Command line Swift tools

## How It Works

1. **Swift generates coverage data** using `swift test --enable-code-coverage`
2. **Coverage data is in Xcode format** (`.profdata` files)
3. **Codecov automatically detects** and processes Swift coverage
4. **No conversion needed** - Codecov handles Swift/Xcode format natively

## Setup Instructions

### 1. Sign Up for Codecov

1. Visit [codecov.io](https://codecov.io)
2. Sign in with GitHub (recommended)
3. Authorize Codecov to access your repositories

### 2. Add Your Repository

1. Click "Add repository" 
2. Select `lekman/magsafe-buskill`
3. Codecov will provide a token (optional for public repos)

### 3. Workflow Configuration

The workflow is already configured in `.github/workflows/test.yml`:

```yaml
- name: Run tests with coverage
  run: swift test --enable-code-coverage
  
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    xcode: true # Enable Xcode coverage format
    xcode_archive_path: .build/debug/codecov
```

### 4. Get Your Badge

After your first test run:
1. Go to your Codecov dashboard
2. Click "Settings" → "Badge"
3. Copy the markdown badge
4. Add to README.md or docs/qa.md

Example badge (already configured):
```markdown
[![codecov](https://codecov.io/gh/lekman/magsafe-buskill/graph/badge.svg?token=AshUsxKtAI)](https://codecov.io/gh/lekman/magsafe-buskill)
```

## What Gets Measured

### Coverage Metrics
- **Line coverage**: Which lines of code were executed
- **Branch coverage**: Which decision paths were taken
- **Function coverage**: Which functions were called

### Swift-Specific Features
- Protocol coverage
- Extension coverage
- Generic type coverage
- Closure coverage

## Best Practices

### Writing Testable Swift Code

1. **Use dependency injection**
   ```swift
   class PowerMonitor {
       private let notificationCenter: NotificationCenter
       
       init(notificationCenter: NotificationCenter = .default) {
           self.notificationCenter = notificationCenter
       }
   }
   ```

2. **Test edge cases**
   ```swift
   func testPowerDisconnectedWhileArmed() {
       // Test security triggers
   }
   ```

3. **Mock system APIs**
   ```swift
   protocol PowerSource {
       var isConnected: Bool { get }
   }
   ```

### Coverage Goals

- **80%+ coverage**: Good target for most projects
- **Critical paths**: 100% coverage for security features
- **UI code**: Lower coverage acceptable (hard to test)

## Troubleshooting

### "No coverage data found"
- Ensure `swift test --enable-code-coverage` runs successfully
- Check that tests actually execute code

### "Badge not updating"
- Coverage badges cache for performance
- Wait 10 minutes or add `?cacheBust=1` to URL

### "Low coverage reported"
- View detailed report on Codecov dashboard
- Identify untested files
- Add tests for critical paths first

## Advanced Configuration

### codecov.yml

Create `.codecov.yml` for custom settings:

```yaml
coverage:
  precision: 2
  round: down
  range: "70...100"
  
  status:
    project:
      default:
        target: 80%
        threshold: 5%
    patch:
      default:
        target: 80%

comment:
  layout: "reach,diff,flags,tree"
  behavior: default
  require_changes: false
```

### Ignoring Files

Exclude files from coverage:

```yaml
ignore:
  - "Tests/"
  - "**/*Tests.swift"
  - "**/Mock*.swift"
```

## Integration with PR Workflow

Codecov automatically:
1. Comments on PRs with coverage changes
2. Shows coverage diff
3. Fails check if coverage drops significantly
4. Provides detailed line-by-line coverage

## Free Tier Details

### What's Included (Free for Open Source)
- Unlimited public repositories
- Unlimited users
- Coverage history
- PR comments
- Badges
- Detailed reports

### Limitations
- Private repos: 5 free (with limited features)
- No priority support
- Standard data retention

## Alternatives

While Codecov is recommended, alternatives include:

1. **Coveralls** - Similar features, also free for OSS
2. **SonarCloud** - Includes coverage + code quality
3. **Code Climate** - Coverage + maintainability

## Conclusion

Codecov provides excellent Swift support with zero configuration needed beyond enabling coverage in Swift tests. The integration is seamless and provides valuable insights into test coverage for security-critical code like MagSafe Guard.