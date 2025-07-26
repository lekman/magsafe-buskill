# CI/CD Workflows Documentation

This document describes all GitHub Actions workflows used in the MagSafe Guard project.

## Table of Contents

- [Overview](#overview)
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

### 1. Test Suite (`test.yml`)

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

### 2. Commit Message Check (`commit-message-check.yml`)

**Trigger**: Pull requests

**Purpose**: Enforces conventional commit format and blocks prohibited words

**Jobs**:

- `cancel-redundant`: Cancels outdated runs
- `check-commit-messages`:
  - Validates commit format (conventional commits)
  - Checks for blocked words (case-insensitive)
  - Provides detailed feedback on failures

**Required for merge**: Yes ✅

### 3. Enforce Clean History (`enforce-clean-history.yml`)

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

### 4. Security Scanning (`security.yml`)

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

### 5. Security Audit (`security-audit.yml`)

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

### 6. Release Please (`release-please.yml`)

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
