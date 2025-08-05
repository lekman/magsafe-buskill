# Comprehensive Quality Assurance Analysis and Fix

Run full quality assurance checks including SonarCloud analysis, then analyze and fix all issues found.

## Quick Start

```bash
# Standard QA (without SonarCloud)
task qa

# Quick QA for git hooks
task qa:quick

# Full QA with SonarCloud
task qa:full

# Auto-fix all fixable issues
task qa:fix
```

## Available QA Task Commands

### Core QA Tasks
- `task qa` - Standard QA suite (lint, test, coverage, security)
- `task qa:quick` - Fast checks for git hooks (lint + secrets)
- `task qa:fix` - Auto-fix all fixable issues
- `task qa:full` - Full suite including SonarCloud analysis

### Module-Specific Tasks
- `task swift:lint` - Check Swift code style
- `task swift:lint:fix` - Auto-fix Swift style issues
- `task swift:test` - Run Swift tests (parallel by default)
- `task swift:test:coverage` - Run tests with coverage report
- `task markdown:lint` - Check markdown formatting
- `task markdown:lint:fix` - Auto-fix markdown issues
- `task security:scan` - Run all security checks
- `task sonar:scan` - Run SonarCloud analysis (requires token)
- `task sonar:simulate` - Local analysis without SonarCloud

## Step-by-Step QA Process

### 1. Run Initial QA Check

```bash
# For standard development
task qa

# For pre-push verification
task qa:full
```

### 2. Fix Linting Issues

If linting errors are found:

```bash
# Auto-fix all fixable issues
task qa:fix

# Or fix individually
task swift:lint:fix
task markdown:lint:fix
```

### 3. Handle Test Failures

#### Ensure Tests Run in Parallel

Swift tests are configured to run in parallel to avoid initialization hangs:

```yaml
# In swift.yml, tests run with:
swift test --parallel --num-workers 1
```

This configuration:
- Uses `--parallel` flag to enable parallel execution
- Limits to 1 worker to avoid race conditions
- Prevents common Swift test runner hangs
- Captures output cleanly without shell errors

#### Debug Test Failures

```bash
# Run tests with verbose output
swift test --parallel --num-workers 1

# Run specific test
swift test --filter TestClassName

# Debug with LLDB
swift test --parallel --num-workers 1 --enable-test-debugging
```

Common test fixes:
- **Timing issues**: Use `XCTestExpectation` with proper timeouts
- **Mock configuration**: Ensure mocks match protocol requirements
- **Async issues**: Use `async`/`await` with `@MainActor` where needed
- **Isolation issues**: Reset shared state in `setUp()`/`tearDown()`

### 4. Analyze Code Coverage

```bash
# Generate coverage report
task swift:test:coverage

# Generate HTML report for detailed view
task swift:test:html
```

Coverage thresholds:
- **Target**: 80% overall coverage
- **Baseline**: Check `docs/maintainers/test-coverage.md`
- **Focus**: Business logic and services

#### Improve Coverage

**Option A: Add Missing Tests**
```swift
// Example test for uncovered service
func testServiceBehavior() async throws {
    // Arrange
    let mockDependency = MockDependency()
    let service = Service(dependency: mockDependency)
    
    // Act
    let result = try await service.performAction()
    
    // Assert
    XCTAssertEqual(result, expectedValue)
    XCTAssertTrue(mockDependency.wasCalled)
}
```

**Option B: Extract Testable Logic**
```swift
// Before: Mixed UI and logic
class ViewController {
    func handlePowerChange(_ hasACPower: Bool) {
        if !hasACPower && isArmed {
            NSApp.terminate(nil)  // Hard to test
        }
    }
}

// After: Separated concerns
class PowerMonitorCore {
    func shouldTriggerAction(hasACPower: Bool, isArmed: Bool) -> Bool {
        return !hasACPower && isArmed
    }
}

class ViewController {
    let core = PowerMonitorCore()
    
    func handlePowerChange(_ hasACPower: Bool) {
        if core.shouldTriggerAction(hasACPower: hasACPower, isArmed: isArmed) {
            NSApp.terminate(nil)
        }
    }
}
```

**Option C: Configure Coverage Exclusions**

Update exclusions in multiple places:

1. **Taskfile.yml** (swift:test:coverage):
   ```yaml
   -ignore-filename-regex=".*Tests.*|.*Mock.*|.*\.pb\.swift|.*generated.*"
   ```

2. **sonar-project.properties**:
   ```properties
   sonar.coverage.exclusions=**/Tests/**,**/Mock*.swift,**/Generated/**
   ```

3. **.github/workflows/test.yml**:
   ```yaml
   --ignore-filename-regex=".*Tests\.swift|.*Mocks?\.swift|.*Generated.*"
   ```

### 5. Check for Pull Requests and Scan Results

#### Check GitHub Workflow Runs

```bash
# Check workflow runs for current branch
task git:runs:check

# Check specific branch
task git:runs:check BRANCH=main

# Show only failed runs
task git:runs:check STATUS=failure

# Show more runs
task git:runs:check LIMIT=20
```

This helps identify:
- ❌ Failed workflow runs that need fixing
- 🔄 In-progress runs to wait for
- ✅ Successful runs for confidence
- 🚫 Cancelled runs that may need re-running

#### Check for Active Pull Requests

```bash
# List all open pull requests
task git:pr:list

# If a PR exists, note the PR number for the next steps
```

#### Download PR-Specific Scan Results

If you have an active PR:

```bash
# Download SonarCloud PR analysis
task sonar:download:pr PR_NUMBER=<number>

# Download GitHub comments (including GHAS/CodeQL alerts)
task git:pr:comments PR_NUMBER=<number>

# View downloaded results
cat .sonarcloud/pr-*-report.md | less
cat .github/pr-comments/*.json | jq '.comment_content' | less
```

#### Run SonarCloud Analysis

```bash
# With token in .env
task sonar:scan

# Without token (local simulation)
task sonar:simulate
task sonar:view
```

#### Download and Review All Findings

```bash
# Download all findings (main branch)
task sonar:download

# Review findings
cat .sonarcloud/sonarcloud-findings.txt | less

# Or view simulation report
cat .sonarcloud/simulation-report.txt
```

#### Fix Issues by Priority

**Priority Order:**
1. **🚨 GHAS Security Alerts** - Fix immediately (from PR comments)
2. **🐛 Bugs** - Fix immediately (reliability issues)
3. **🔓 Vulnerabilities** - Fix immediately (security issues)
4. **🔍 Security Hotspots** - Review and fix or mark safe
5. **🧹 Code Smells** - Fix if impacting maintainability

**Review GHAS Alerts from PR Comments:**
```bash
# Extract security alerts from PR comments
cat .github/pr-comments/*.json | jq -r '
  select(.comment_type == "security_alert") | 
  "\(.severity): \(.comment_content)"'

# Extract code review comments
cat .github/pr-comments/*.json | jq -r '
  select(.comment_type == "code_review") | 
  "\(.path):\(.line): \(.comment_content)"'
```

**Common SonarCloud Fixes:**

```swift
// S1066: Merge nested if statements
// Before
if condition1 {
    if condition2 {
        doSomething()
    }
}

// After
if condition1 && condition2 {
    doSomething()
}

// S3087: Extract nested closures
// Before
view.onAppear {
    DispatchQueue.main.async {
        viewModel.items.forEach { item in
            process(item)
        }
    }
}

// After
view.onAppear(perform: handleAppear)

private func handleAppear() {
    DispatchQueue.main.async {
        viewModel.items.forEach(process)
    }
}

// S1301: Replace switch with if for readability
// Before
switch value {
case true:
    return "yes"
default:
    return "no"
}

// After
return value ? "yes" : "no"
```

### 6. Security Scanning

```bash
# Run all security checks
task security:scan

# Individual checks
task security:secrets    # Scan for hardcoded secrets
task security:semgrep    # Static analysis
task security:pins       # Check GitHub Action pins
```

#### Check GitHub Advanced Security (GHAS) Alerts

GHAS alerts appear in PR comments:

```bash
# Download PR comments including GHAS alerts
task git:pr:comments PR_NUMBER=<number>

# Filter for security alerts
find .github/pr-comments -name "*.json" -exec jq -r '
  select(.comment_type == "security_alert") | 
  "[\(.severity)] \(.path):\(.line) - \(.comment_content)"' {} \;
```

Common GHAS findings:
- **Cleartext logging**: Remove sensitive data from logs
- **Hard-coded credentials**: Move to environment variables
- **SQL injection**: Use parameterized queries
- **Path traversal**: Validate file paths

Fix security issues:
- **Secrets**: Move to environment variables or keychain
- **Pins**: Run `task security:pin-actions` to fix
- **Dependencies**: Run `task security:dependabot` for automated updates
- **GHAS alerts**: Address each finding based on severity

### 7. Generate SBOM

```bash
# Generate Software Bill of Materials
task swift:sbom
```

This creates:
- `sbom.spdx` - SPDX format for compliance
- `sbom-deps.json` - JSON dependency list

### 8. Final Verification

```bash
# Run full QA to ensure all fixes work
task qa:full

# If using git hooks
git commit -m "fix: resolve QA issues"
```

## Troubleshooting

### Tests Hang or Timeout

```bash
# Use parallel execution (already configured)
swift test --parallel --num-workers 1

# Or increase timeout
swift test --parallel --num-workers 1 --enable-test-debugging
```

### Coverage Not Generated

```bash
# Ensure build with coverage
swift build --enable-code-coverage

# Then run tests
task swift:test:coverage
```

### SonarCloud Token Issues

```bash
# Add token to .env
echo 'SONAR_TOKEN=your-token-here' >> .env

# Or use simulation mode
task sonar:simulate
```

### Lint Fix Not Working

```bash
# Check SwiftLint version
swiftlint version

# Update if needed
brew upgrade swiftlint
```

## CI/CD Integration

The QA tasks integrate with GitHub Actions:

1. **Pull Requests**: Runs `task qa` automatically
2. **Main Branch**: Runs `task qa:full` with SonarCloud
3. **Pre-commit Hooks**: Uses `task qa:quick`

## Best Practices

1. **Check Workflow Runs**: Use `task git:runs:check` to see CI status
2. **Check PRs First**: Use `task git:pr:list` to see active PRs
3. **Download PR Feedback**: Get SonarCloud and GHAS results for PRs
4. **Run QA Early**: Use `task qa:quick` during development
5. **Fix Incrementally**: Address issues as they arise
6. **Maintain Coverage**: Don't let it drop below baseline
7. **Prioritize Security**: Fix GHAS alerts and vulnerabilities immediately
8. **Document Exclusions**: Explain why code is excluded
9. **Use Auto-fix**: Let tools fix formatting issues

### PR-Based Workflow

When working on a PR:

```bash
# 1. Check workflow runs for your branch
task git:runs:check

# 2. Check for active PRs
task git:pr:list

# 3. Download PR-specific feedback
task sonar:download:pr PR_NUMBER=21
task git:pr:comments PR_NUMBER=21

# 4. Review and fix issues
cat .sonarcloud/pr-21-report.md
find .github/pr-comments -name "*.json" -exec jq . {} \;

# 5. Run QA to verify fixes
task qa:full

# 6. Check if CI passes after push
task git:runs:check STATUS=in_progress
```

### Handling Failed Workflow Runs

If `task git:runs:check` shows failures:

```bash
# 1. View failed run details
gh run view <run-id> --log-failed

# 2. Re-run failed jobs only
gh run rerun <run-id> --failed

# 3. Clean up old failed runs
task git:delete-runs STATUS=failure
```

## Sentry MCP Integration

### Setting Up Sentry MCP

The project now includes Sentry MCP (Model Context Protocol) integration for advanced error analysis and feature flag management:

```bash
# Ensure Sentry MCP is configured in .mcp.json
# The MCP server provides direct access to Sentry data and AI analysis
```

### Feature Flags Framework

The project implements a robust feature flags framework that integrates with Sentry:

#### Implementation Details

```swift
// Feature flags are defined in FeatureFlagsCore.swift
public struct FeatureFlag {
    public let key: String
    public let defaultValue: Bool
    public let title: String
    public let description: String
}

// Key feature flags:
FeatureFlags.locationTracking     // Enable/disable location-based features
FeatureFlags.enhancedSecurity     // Toggle advanced security features
FeatureFlags.debugLogging         // Control verbose logging
FeatureFlags.betaFeatures         // Access to experimental features
```

#### Using Feature Flags to Prevent Crashes

```bash
# 1. Monitor for crashes in production
mcp__sentry__search_issues organizationSlug="your-org" naturalLanguageQuery="crashes in last 24 hours"

# 2. If critical crash found, immediately disable problematic feature
# Update feature flag in Sentry UI or via API
mcp__sentry__update_issue organizationSlug="your-org" issueId="ISSUE-ID" status="resolved"

# 3. Use feature flag to bypass crash-prone code
if FeatureFlagsManager.shared.isEnabled(.locationTracking) {
    // Location tracking code that might crash
} else {
    // Safe fallback behavior
}
```

### Sentry MCP Commands for QA

#### Error Analysis

```bash
# Search for recent errors
mcp__sentry__search_issues organizationSlug="your-org" naturalLanguageQuery="errors in MagSafe Guard today"

# Get detailed crash analysis with AI
mcp__sentry__analyze_issue_with_seer issueUrl="https://your-org.sentry.io/issues/PROJECT-123"

# Search for specific event types
mcp__sentry__search_events organizationSlug="your-org" naturalLanguageQuery="permission denied errors"

# Get crash statistics
mcp__sentry__search_events organizationSlug="your-org" naturalLanguageQuery="count of crashes by version"
```

#### Feature Flag Management Workflow

1. **Identify Problem via Sentry**:
   ```bash
   # Find crashes related to specific features
   mcp__sentry__search_issues organizationSlug="your-org" naturalLanguageQuery="location permission crashes"
   ```

2. **Disable Feature Remotely**:
   - Update feature flag in Sentry UI
   - Or use runtime configuration
   - App checks flag status on startup

3. **Debug with AI Team**:
   ```bash
   # Use tech-lead to orchestrate debugging
   @tech-lead-orchestrator "Analyze location permission crash from Sentry issue PROJECT-123"
   
   # Tech-lead will coordinate:
   # - api-architect: Review system API usage
   # - backend-developer: Analyze service implementation
   # - code-reviewer: Security and error handling audit
   ```

4. **Fix and Test**:
   ```bash
   # Run comprehensive tests
   task qa:full
   
   # Test with feature flag variations
   FEATURE_FLAGS_OVERRIDE="locationTracking=false" swift test
   ```

5. **Progressive Rollout**:
   - Enable feature for beta users first
   - Monitor Sentry for new issues
   - Gradually increase rollout percentage

### AI-Powered Debugging Workflow

#### Step 1: Identify Issue with Sentry MCP

```bash
# Get AI analysis of crash
mcp__sentry__analyze_issue_with_seer organizationSlug="your-org" issueId="MAGSAFE-123"

# Download crash attachments (logs, screenshots)
mcp__sentry__get_event_attachment organizationSlug="your-org" projectSlug="magsafe-guard" eventId="event-id"
```

#### Step 2: Orchestrate AI Team

```bash
# Use tech-lead to coordinate specialists
@tech-lead-orchestrator "Debug and fix the crash identified in Sentry issue MAGSAFE-123 based on this analysis: [paste Seer analysis]"

# Tech-lead will route to appropriate agents:
# - performance-optimizer: For performance-related crashes
# - api-architect: For system API failures
# - backend-developer: For service logic issues
# - code-reviewer: For final security review
```

#### Step 3: Implement Fix with Feature Flag Protection

```swift
// Wrap fix in feature flag for safe deployment
if FeatureFlagsManager.shared.isEnabled(.crashFix123) {
    // New implementation
    implementSafePowerMonitoring()
} else {
    // Original implementation (with known crash)
    legacyPowerMonitoring()
}
```

#### Step 4: Monitor and Iterate

```bash
# Monitor fix effectiveness
mcp__sentry__search_events organizationSlug="your-org" naturalLanguageQuery="errors after deploying fix for MAGSAFE-123"

# Check crash statistics
mcp__sentry__search_events organizationSlug="your-org" naturalLanguageQuery="count of crashes by version in last 7 days"

# Get user impact analysis
mcp__sentry__get_issue_details organizationSlug="your-org" issueId="MAGSAFE-123"
```

### Best Practices for Sentry + Feature Flags

1. **Proactive Monitoring**:
   ```bash
   # Set up regular crash checks
   mcp__sentry__search_issues organizationSlug="your-org" naturalLanguageQuery="new crashes in last hour"
   ```

2. **Feature Flag Hygiene**:
   - Document each flag's purpose
   - Set expiration dates for temporary flags
   - Remove flags after successful rollout
   - Monitor flag usage in Sentry

3. **Crash Response Protocol**:
   - High severity crash → Disable feature immediately
   - Medium severity → Test fix with flag protection
   - Low severity → Include fix in next release

4. **Integration with CI/CD**:
   ```yaml
   # In GitHub Actions
   - name: Check Sentry for Release Issues
     run: |
       # Use Sentry CLI or API to check release health
       sentry-cli releases info ${{ github.sha }}
   ```

### Troubleshooting Sentry MCP

#### Connection Issues

```bash
# Verify MCP connection
# Check Claude Code logs for MCP status

# Test Sentry authentication
mcp__sentry__whoami

# List available organizations
mcp__sentry__find_organizations
```

#### Feature Flag Not Working

```swift
// Debug feature flag evaluation
let flags = FeatureFlagsManager.shared
print("Location tracking enabled: \(flags.isEnabled(.locationTracking))")
print("Flag source: \(flags.evaluationContext)")

// Force refresh flags from Sentry
flags.refreshFlags()
```

#### Missing Crash Data

```bash
# Ensure DSN is configured
mcp__sentry__find_dsns organizationSlug="your-org" projectSlug="magsafe-guard"

# Verify events are being sent
mcp__sentry__search_events organizationSlug="your-org" naturalLanguageQuery="events from device in last hour"
```

## Summary

This comprehensive QA process ensures:
- ✅ Code style consistency (SwiftLint, markdownlint)
- ✅ Test reliability (parallel execution, proper mocks)
- ✅ Coverage maintenance (80% target, smart exclusions)
- ✅ Security compliance (secrets scanning, pinned actions)
- ✅ Code quality (SonarCloud analysis, issue prioritization)
- ✅ Documentation accuracy (SBOM generation, coverage reports)
- ✅ **Production stability (Sentry monitoring, feature flags)**
- ✅ **AI-powered debugging (Sentry MCP + AI agents)**
- ✅ **Crash prevention (remote feature control)**

The combination of taskfile automation, Sentry MCP integration, and AI agent orchestration provides a robust quality assurance framework that can quickly identify, analyze, and resolve production issues.