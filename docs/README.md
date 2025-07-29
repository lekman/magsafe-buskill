# MagSafe Guard Documentation

Welcome to the MagSafe Guard documentation. This directory contains all project documentation organized by audience and category.

## 🚀 Quick Start by Role

### 👤 For Users

- [Installation Guide](users/installation-guide.md) - How to install and set up MagSafe Guard
- [User Guide](users/user-guide.md) - Using MagSafe Guard effectively
- [Troubleshooting](users/troubleshooting.md) - Common issues and solutions
- [Security Policy](SECURITY.md) - How to report security issues

### 🔧 For Maintainers & Developers

- [Building and Running](maintainers/building-and-running.md) - Development setup
- [Testing Guide](maintainers/testing-guide.md) - Running and writing tests
- [Architecture Overview](architecture/architecture-overview.md) - System design
- [Code Signing Setup](maintainers/code-signing.md) - Certificate configuration
- [CloudKit Crash Fix](maintainers/cloudkit-crash-fix.md) - Startup issue resolution
- [Test Coverage](maintainers/test-coverage.md) - Coverage reports

### 🔒 For Security & Compliance Officers

- [Security Implementation Guide](security/security-implementation-guide.md) - Security architecture
- [SSDLC Case Study](security/ssdlc-case-study.md) - Secure development practices
- [Software Bill of Materials](security/sbom-guide.md) - Component transparency
- [Authentication Hardening](security/authentication-hardening.md) - Biometric security

### 🚀 For DevOps Engineers

- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions & required secrets
- [Git Hooks](devops/git-hooks.md) - Automated code quality checks
- [Testing in CI](devops/testing-in-ci.md) - CI testing configuration
- [Maintenance Tasks](../tasks/README.md) - Taskfile automation

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
- [Code Signing](maintainers/code-signing.md) - macOS code signing setup
- [Code Signing Implementation](maintainers/code-signing-implementation.md) - Implementation details
- [CloudKit Crash Fix](maintainers/cloudkit-crash-fix.md) - Troubleshooting startup crashes
- [Acceptance Tests](maintainers/acceptance-tests.md) - Manual testing procedures
- [Maintenance Tasks](../tasks/README.md) - Taskfile commands and workflows
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues and solutions

## 👤 Users

- [Installation Guide](users/installation-guide.md) - Getting started with MagSafe Guard
- [User Guide](users/user-guide.md) - Features and usage instructions
- [Troubleshooting](users/troubleshooting.md) - Solving common problems

## 📁 Directory Structure

```ini
docs/
├── README.md               # This file - documentation index
├── architecture/           # System design and architecture
├── devops/                 # CI/CD and automation
├── security/               # Security documentation
├── maintainers/            # Developer guides
├── users/                  # End-user documentation
├── PRD.md                  # Product requirements
├── REQUIREMENTS.md         # Technical requirements
├── CHANGELOG.md            # Release history
├── CONTRIBUTORS.md         # Acknowledgments
├── QA.md                   # Quality procedures
└── SECURITY.md             # Security policy
```

## 🔍 Finding Documentation

### Users

- **Installing MagSafe Guard**: [Installation Guide](users/installation-guide.md)
- **Using the App**: [User Guide](users/user-guide.md)
- **Having Problems?**: [User Troubleshooting](users/troubleshooting.md)

### Developers

- **Getting Started**: [Building and Running](maintainers/building-and-running.md)
- **Contributing**: [Testing Guide](maintainers/testing-guide.md) and [Git Hooks](devops/git-hooks.md)
- **Architecture**: [Architecture Overview](architecture/architecture-overview.md)
- **Code Signing Issues**: [Code Signing Setup](maintainers/code-signing.md)

### Security Officers

- **Security Architecture**: [Security Implementation Guide](security/security-implementation-guide.md)
- **Compliance**: [SBOM Guide](security/sbom-guide.md) and [SSDLC Case Study](security/ssdlc-case-study.md)
- **Vulnerability Reporting**: [Security Policy](SECURITY.md)

### DevOps Engineers

- **CI/CD Setup**: [CI/CD Workflows](devops/ci-cd-workflows.md) (includes all required secrets)
- **Automation**: [Maintenance Tasks](../tasks/README.md)
- **Build Optimization**: [CI Caching Strategy](devops/ci-caching-strategy.md)

## 📝 Documentation Standards

- All documentation is written in Markdown
- Files are organized by category in subdirectories
- Use descriptive filenames with kebab-case
- Include a header with title and brief description
- Keep documentation up-to-date with code changes
