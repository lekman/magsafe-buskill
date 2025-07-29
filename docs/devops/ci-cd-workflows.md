# CI/CD Workflows Documentation

This document describes all GitHub Actions workflows used in the MagSafe Guard project and the required secrets for their operation.

## Table of Contents

- [Overview](#overview)
- [Required GitHub Secrets](#required-github-secrets)
- [Workflow Efficiency](#workflow-efficiency)
- [Core Workflows](#core-workflows)
- [Security Workflows](#security-workflows)
- [Release Workflows](#release-workflows)
- [Composite Actions](#composite-actions)
- [Branch Protection Integration](#branch-protection-integration)
- [Troubleshooting](#troubleshooting)

## Overview

Our CI/CD pipeline uses GitHub Actions to automate testing, security scanning, and deployment processes. All workflows are designed with efficiency and security in mind.

### Key Features

- **Automatic redundant workflow cancellation** - Saves resources by cancelling outdated runs
- **Comprehensive security scanning** - Multiple layers of security checks
- **Commit message enforcement** - Maintains clean git history
- **Automated testing** - Swift tests with code coverage
- **Release automation** - Semantic versioning with release-please

## Required GitHub Secrets

### Code Signing Secrets (for Release Builds)

These secrets are required for signing macOS applications with a Developer ID certificate:

#### `SIGNING_CERTIFICATE_P12_DATA`

- **Description**: Base64-encoded Developer ID Application certificate in P12 format
- **Used in**: `.github/workflows/build-sign.yml` (release builds)
- **How to generate**:

  ```bash
  # Export certificate from Keychain Access
  # 1. Open Keychain Access
  # 2. Find your "Developer ID Application" certificate
  # 3. Right-click → Export
  # 4. Save as .p12 with a password

  # Convert to base64
  base64 -i Certificates.p12 -o certificate_base64.txt

  # Copy contents of certificate_base64.txt to GitHub secret
  ```

#### `SIGNING_CERTIFICATE_PASSWORD`

- **Description**: Password used when exporting the P12 certificate
- **Used in**: `.github/workflows/build-sign.yml` (release builds)
- **Example**: `MySecureP12Password123!`

### Apple Notarization Secrets (for Release Builds)

These secrets are required for notarizing the application with Apple:

#### `APPLE_ID`

- **Description**: Your Apple ID email address used for notarization
- **Used in**: `.github/workflows/build-sign.yml` (notarization step)
- **Example**: `developer@example.com`

#### `APPLE_APP_SPECIFIC_PASSWORD`

- **Description**: App-specific password for notarization (NOT your regular Apple ID password)
- **Used in**: `.github/workflows/build-sign.yml` (notarization step)
- **How to generate**:
  1. Go to https://appleid.apple.com
  2. Sign in with your Apple ID
  3. Navigate to Security → App-Specific Passwords
  4. Click "Generate Password"
  5. Label it "MagSafe Guard Notarization"
  6. Copy the generated password

#### `APPLE_TEAM_ID`

- **Description**: Your Apple Developer Team ID (10-character alphanumeric)
- **Used in**: `.github/workflows/build-sign.yml` (notarization step)
- **How to find**:

  ```bash
  # Using Xcode
  xcrun altool --list-providers -u "your-apple-id@example.com" -p "app-specific-password"

  # Or find in Apple Developer Portal
  # https://developer.apple.com/account → Membership → Team ID
  ```

- **Example**: `ABC123DEF4`

### SonarCloud Secrets (Optional - for Code Quality)

#### `SONAR_TOKEN`

- **Description**: Authentication token for SonarCloud analysis
- **Used in**: `.github/workflows/test.yml`, `.github/workflows/sonarcloud.yml`
- **How to generate**:
  1. Log in to https://sonarcloud.io
  2. Go to Account → Security
  3. Generate a new token
  4. Name it "GitHub Actions"
- **Required**: Only if using SonarCloud integration

### Setting Up Secrets

Via GitHub Web Interface:

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its name and value

Via GitHub CLI:

```bash
# Authenticate first
gh auth login

# Add secrets
gh secret set SIGNING_CERTIFICATE_P12_DATA < certificate_base64.txt
gh secret set SIGNING_CERTIFICATE_PASSWORD
gh secret set APPLE_ID
gh secret set APPLE_APP_SPECIFIC_PASSWORD
gh secret set APPLE_TEAM_ID
gh secret set SONAR_TOKEN  # Optional
```

## Workflow Efficiency

### Cancel Redundant Workflows

All workflows include automatic cancellation of redundant runs to optimize CI/CD resources:

- **Location**: `.github/actions/cancel-redundant-workflows/`
- **Purpose**: Cancels older in-progress runs when new commits are pushed
- **Benefits**:
  - Reduces CI/CD costs
  - Faster feedback for latest changes
  - Prevents queue congestion

#### How It Works

1. When a workflow starts, it first runs the `cancel-redundant` job
2. This job identifies older runs for the same branch/PR
3. Older runs are cancelled before proceeding
4. All subsequent jobs wait for this to complete

## Core Workflows

### 1. Build and Sign (`build-sign.yml`)

**Trigger**: Push to main/develop, Pull requests to main, Git tags, Manual dispatch

**Purpose**: Builds and signs the macOS application with appropriate certificates

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `build-and-sign`:
  - Builds the application with Swift Bundler
  - Signs based on context:
    - **Pull Requests**: Ad-hoc signing (no certificate)
    - **Branch pushes**: Development signing
    - **Tag pushes**: Release signing + notarization
  - Creates DMG for releases
  - Uploads artifacts

**Required Secrets** (for release builds only):

- `SIGNING_CERTIFICATE_P12_DATA`
- `SIGNING_CERTIFICATE_PASSWORD`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

**Required for merge**: No ❌

### 2. Test Suite (`test.yml`)

**Trigger**: Push to any branch, Pull requests

**Purpose**: Runs Swift tests and generates code coverage

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `test`:
  - Builds the Swift package
  - Runs all unit tests
  - Generates code coverage report
  - Uploads to Codecov

**Required for merge**: Yes ✅

### 3. Commit Message Check (`commit-message-check.yml`)

**Trigger**: Pull requests

**Purpose**: Enforces conventional commit format and blocks prohibited words

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `check-commit-messages`:
  - Validates commit format (conventional commits)
  - Checks for blocked words (case-insensitive)
  - Provides detailed feedback on failures

**Required for merge**: Yes ✅

### 4. Enforce Clean History (`enforce-clean-history.yml`)

**Trigger**: Pull requests

**Purpose**: Deep scan of entire commit history for prohibited content

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `enforce-clean-commits`:
  - Scans full commit history
  - Provides detailed remediation instructions
  - Creates GitHub Step Summary with fix commands

**Required for merge**: Yes ✅

## Security Workflows

### 5. Security Scanning (`security.yml`)

**Trigger**: Pull requests, Push to main, Weekly schedule

**Purpose**: Comprehensive security analysis

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `basic-checks`: Quick security validations
- `codeql`: Static analysis for vulnerabilities
- `dependency-review`: Checks for vulnerable dependencies
- `trufflehog`: Secret scanning
- `security-policy`: Validates SECURITY.md exists
- `semgrep`: Additional SAST scanning
- `license-scan`: License compliance
- `scorecard`: OpenSSF security scorecard (reports to GHAS only, not published to dashboard)
- `security-summary`: Aggregates all results

**Required for merge**: Yes (basic-checks) ✅

### 6. Security Audit (`security-audit.yml`)

**Trigger**: Weekly schedule, Manual dispatch

**Purpose**: Detailed security audit reports

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `audit-report`:
  - Generates comprehensive security report
  - Uploads artifacts for review
  - 30-day retention

**Required for merge**: No ❌

## Release Workflows

### 7. Release Please (`release-please.yml`)

**Trigger**: Push to main branch

**Purpose**: Automated release management

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `release-please`:
  - Creates release PRs automatically
  - Updates CHANGELOG.md
  - Manages version bumps
  - Creates GitHub releases

**Required for merge**: No ❌

## Composite Actions

### Cancel Redundant Workflows Action

**Location**: `.github/actions/cancel-redundant-workflows/action.yml`

**Usage**:

```yaml
- uses: ./.github/actions/cancel-redundant-workflows
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    only-same-workflow: true
```

**Parameters**:

- `token`: GitHub token with workflow permissions
- `only-same-workflow`: Only cancel runs of the same workflow file (default: true)

**Logic**:

- For PRs: Cancels runs for the same PR number
- For pushes: Cancels older runs for the same branch
- Provides detailed logging of cancelled runs

## Branch Protection Integration

The following workflows are configured as required status checks in branch protection:

1. ✅ `Test Suite`
2. ✅ `Validate Commit Messages`
3. ✅ `Enforce Clean Commit History`
4. ✅ `Security Scan / basic-checks`
5. ✅ `CodeQL`

These checks must pass before merging to protected branches.

**Note**: Direct push protection is handled by GitHub's branch protection rules, not by workflow checks.

## Troubleshooting

### Workflow Cancelled Unexpectedly

If your workflow was cancelled:

1. Check if a newer commit was pushed to the same branch/PR
2. Look at the workflow logs for "Cancel Redundant Workflows" job
3. This is normal behavior to save resources

### Commit Message Check Failed

Common issues:

- Not following conventional commit format
- Contains blocked words (claude, anthropic, co-authored)
- See [Commit Message Enforcement](commit-message-enforcement.md)

### Security Scan Failed

1. Check the specific security job that failed
2. Review the logs for detailed vulnerability information
3. Fix identified issues and push new commits

### Test Suite Failed

1. Check test logs for specific failures
2. Ensure macOS deployment target is correct (13.0+)
3. Verify all Swift packages are resolved

## Best Practices

1. **Always wait for CI** - Don't merge until all checks pass
2. **Fix failures promptly** - Address CI failures before adding new commits
3. **Monitor security scans** - Pay attention to new vulnerabilities
4. **Keep workflows updated** - Regularly update action versions

## Workflow Permissions

All workflows use minimal required permissions:

- Read access to code
- Write access to pull requests (for comments)
- Write access to actions (for cancellation)

## Future Improvements

- [ ] Add performance benchmarking
- [ ] Implement deployment workflows
- [ ] Add visual regression testing
- [ ] Enhance security scanning coverage
