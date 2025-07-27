# MagSafe Guard Documentation

Welcome to the MagSafe Guard documentation. This directory contains all project documentation organized by category.

## 📋 Project Documentation

- [Product Requirements Document (PRD)](PRD.md) - Project scope, features, and requirements
- [Requirements](REQUIREMENTS.md) - Detailed technical and functional requirements
- [Changelog](CHANGELOG.md) - Version history and release notes
- [Contributors](CONTRIBUTORS.md) - Project contributors and acknowledgments
- [Quality Assurance](QA.md) - Testing procedures and quality standards
- [Security Policy](SECURITY.md) - Security guidelines and vulnerability reporting

## 🏗️ Architecture

- [Architecture Overview](architecture/architecture-overview.md) - High-level system design
- [Authentication Flow Design](architecture/auth-flow-design.md) - Biometric authentication implementation
- [Menu Bar App Guide](architecture/menu-bar-app-guide.md) - macOS menu bar application structure
- [Menu Bar Design Guide](architecture/menu-bar-design-guide.md) - UI/UX design patterns for menu bar
- [Power Monitor Service Guide](architecture/power-monitor-service-guide.md) - Power adapter detection service
- [Demo Window Guide](architecture/demo-window-guide.md) - Demo interface implementation
- [Settings and Persistence Guide](architecture/settings-persistence-guide.md) - User settings and configuration storage

## 🔧 DevOps

- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions automation
- [CI Caching Strategy](devops/ci-caching-strategy.md) - Build optimization techniques
- [Testing in CI](devops/testing-in-ci.md) - Continuous integration testing setup
- [Git Hooks](devops/git-hooks.md) - Pre-commit and commit-msg hooks
- [Commit Message Enforcement](devops/commit-message-enforcement.md) - Conventional commits
- [Codecov Swift](devops/codecov-swift.md) - Code coverage integration
- [SonarCloud Fixes](devops/sonarcloud-fixes.md) - Code quality improvements

## 🔒 Security

- [Security Implementation Guide](security/security-implementation-guide.md) - Security best practices
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security measures
- [SSDLC Case Study](security/ssdlc-case-study.md) - Secure Software Development Lifecycle
- [Software Bill of Materials (SBOM)](security/sbom-guide.md) - Supply chain transparency and compliance
- [Semgrep Integration](security/semgrep.md) - Static security analysis
- [Snyk Integration](security/snyk-integration.md) - Dependency vulnerability scanning
- [Snyk Policy Justification](security/snyk-evaluatepolicy-justification.md) - Security policy rationale

## 👥 Maintainers

- [Building and Running](maintainers/building-and-running.md) - Development setup guide
- [Testing Guide](maintainers/testing-guide.md) - Unit and integration testing
- [Test Coverage](maintainers/test-coverage.md) - Coverage reports and targets
- [Maintenance Tasks](../tasks/README.md) - Taskfile commands and workflows
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues and solutions

## 📁 Directory Structure

```ini
docs/
├── README.md               # This file
├── architecture/           # System design and architecture
├── devops/                 # CI/CD and automation
├── security/               # Security documentation
├── maintainers/            # Developer guides
└── archive/                # Deprecated documentation (excluded from index)
```

## 🔍 Finding Documentation

- **Getting Started**: See [Building and Running](maintainers/building-and-running.md)
- **Contributing**: Check the [Testing Guide](maintainers/testing-guide.md) and [Git Hooks](devops/git-hooks.md)
- **Architecture Questions**: Start with [Architecture Overview](architecture/architecture-overview.md)
- **Security Concerns**: Review [Security Implementation Guide](security/security-implementation-guide.md)

## 📝 Documentation Standards

- All documentation is written in Markdown
- Files are organized by category in subdirectories
- Use descriptive filenames with kebab-case
- Include a header with title and brief description
- Keep documentation up-to-date with code changes
