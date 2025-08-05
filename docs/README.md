# MagSafe Guard Documentation Index

This documentation is organized by audience and role to help you find the information you need quickly.

## 🚀 Quick Start by Role

### For Users

- [Building and Running](maintainers/building-and-running.md) - Get MagSafe Guard running on your Mac
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues and solutions
- [Feature Flags](features/flags.md) - Configure advanced features
- [Accessibility Features](features/accessibility.md) - VoiceOver and accessibility support

### For Contributors

- [Product Requirements Document (PRD)](PRD.md) - Project vision and scope
- [Requirements](REQUIREMENTS.md) - Detailed technical specifications
- [Architecture Overview](architecture/architecture-overview.md) - System design
- [Testing Guide](maintainers/testing-guide.md) - How to write and run tests
- [Git Hooks](devops/git-hooks.md) - Commit standards and automation

### For Maintainers

- [Development Setup](DEVELOPMENT.md) - Complete development environment
- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions and automation
- [Code Signing Guide](maintainers/code-signing.md) - macOS app signing process
- [Crash Prevention Guide](maintainers/crash-prevention-guide.md) - Stability best practices
- [Release Process](CHANGELOG.md) - Version history and release notes

### For Security Auditors

- [Security Policy](SECURITY.md) - Vulnerability reporting
- [Security Implementation Guide](security/security-implementation-guide.md) - Security architecture
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security
- [SSDLC Case Study](security/ssdlc-case-study.md) - Secure development lifecycle
- [Software Bill of Materials](security/sbom-guide.md) - Dependencies and compliance

## 📚 Documentation by Category

### Project Overview

- [Product Requirements Document (PRD)](PRD.md) - What we're building and why
- [Technical Requirements](REQUIREMENTS.md) - Detailed specifications
- [Quality Assurance](QA.md) - Testing procedures and standards
- [Contributors](CONTRIBUTORS.md) - Project acknowledgments
- [Changelog](CHANGELOG.md) - Release history

### Architecture & Design

- [Architecture Overview](architecture/architecture-overview.md) - High-level system design
- [Swift Project Architecture: Best Practices](architecture/swift-project-architecture-practices.md) - Swift patterns and practices
- [Power Monitor Service Guide](architecture/power-monitor-service-guide.md) - Core detection service
- [Authentication Flow Design](architecture/auth-flow-design.md) - Biometric authentication
- [Menu Bar App Guide](architecture/menu-bar-app-guide.md) - macOS menu bar implementation
- [Menu Bar Design Guide](architecture/menu-bar-design-guide.md) - UI/UX patterns
- [Settings and Persistence Guide](architecture/settings-persistence-guide.md) - Configuration management
- [Demo Window Guide](architecture/demo-window-guide.md) - Demo mode implementation

### Development & Testing

- [Development Setup](DEVELOPMENT.md) - Complete development guide
- [Building and Running](maintainers/building-and-running.md) - Quick start guide
- [Testing Guide](maintainers/testing-guide.md) - Unit and integration testing
- [Test Coverage](maintainers/test-coverage.md) - Coverage reports and metrics
- [Acceptance Tests](maintainers/acceptance-tests.md) - Manual testing procedures
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues

### Code Quality & Stability

- [Crash Prevention Guide](maintainers/crash-prevention-guide.md) - Building stable macOS apps
- [Crash Quick Reference](maintainers/crash-quick-reference.md) - Debugging crashes
- [Code Signing Guide](maintainers/code-signing.md) - macOS signing process
- [Code Signing Implementation](maintainers/code-signing-implementation.md) - Detailed signing steps

### DevOps & CI/CD

- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions automation
- [CI Caching Strategy](devops/ci-caching-strategy.md) - Build optimization
- [Testing in CI](devops/testing-in-ci.md) - Continuous integration setup
- [Git Hooks](devops/git-hooks.md) - Pre-commit automation
- [Commit Message Enforcement](devops/commit-message-enforcement.md) - Conventional commits
- [Codecov Swift Integration](devops/codecov-swift.md) - Coverage reporting
- [SonarCloud Fixes](devops/sonarcloud-fixes.md) - Code quality improvements

### Security & Compliance

- [Security Policy](SECURITY.md) - Vulnerability disclosure
- [Security Implementation Guide](security/security-implementation-guide.md) - Security architecture
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security measures
- [Logging Privacy](security/logging-privacy.md) - Privacy-preserving logging
- [SSDLC Case Study](security/ssdlc-case-study.md) - Secure development lifecycle
- [SBOM Guide](security/sbom-guide.md) - Supply chain transparency

#### Security Tools & Policies

- [Semgrep Integration](security/semgrep.md) - Static security analysis
- [Snyk Integration](security/snyk-integration.md) - Dependency scanning
- [Snyk Policy Justification](security/snyk-evaluatepolicy-justification.md) - Security exceptions
- [Actions Security Summary](security/ACTIONS_SECURITY_SUMMARY.md) - GitHub Actions security
- [Security Workflows](security/SECURITY_WORKFLOWS.md) - Security automation
- [Actions Whitelist](security/actions-whitelist.md) - Approved GitHub Actions
- [Fork PR Policy](security/fork-pr-policy.md) - External contribution security
- [Security Settings](security/security-settings.md) - Repository security configuration

### Features & Configuration

- [Feature Flags](features/flags.md) - Runtime configuration options
- [Accessibility Features](features/accessibility.md) - VoiceOver and accessibility support

### Task Management

- [Taskfile Commands](../tasks/README.md) - Task automation reference

## 📝 Documentation Standards

- **Markdown Format**: All documentation uses GitHub-flavored Markdown
- **Descriptive Names**: Files use kebab-case naming (e.g., `menu-bar-guide.md`)
- **Clear Headers**: Each document starts with a title and brief description
- **Updated Content**: Documentation is kept in sync with code changes
- **Role-Based**: Content is organized by audience needs

## 🔍 Can't Find What You Need?

1. Check the role-based sections above
2. Use your editor's file search in the `docs/` directory
3. Review the [Architecture Overview](architecture/architecture-overview.md) for system understanding
4. See [Troubleshooting](maintainers/troubleshooting.md) for common issues
