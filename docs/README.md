---
layout: default
title: Home
---

# MagSafe Guard Documentation

Welcome to the MagSafe Guard documentation. This guide will help you understand, build, and contribute to the project.

<div style="text-align: center; margin: 2em 0;">
  <img src="assets/magsafe-guard.gif" alt="MagSafe Guard Demo" style="max-width: 100%; height: auto;">
</div>

## 📚 Documentation Index

### 🏗️ Architecture

- [Architecture Overview](architecture/architecture-overview.md) - System design and C4 diagrams
- [Power Monitor Service Guide](architecture/power-monitor-service-guide.md) - Core power detection service
- [Menu Bar App Guide](architecture/menu-bar-app-guide.md) - macOS menu bar implementation
- [Menu Bar Design Guide](architecture/menu-bar-design-guide.md) - UI/UX design principles
- [Demo Window Guide](architecture/demo-window-guide.md) - Testing interface documentation
- [Authentication Flow Design](architecture/auth-flow-design.md) - Security authentication patterns

### 🔧 Development

- [Building and Running](maintainers/building-and-running.md) - Build instructions and development setup
- [Testing Guide](maintainers/testing-guide.md) - Test strategy and implementation
- [Troubleshooting](maintainers/troubleshooting.md) - Common issues and solutions
- [Figma Integration](maintainers/figma.md) - Design collaboration guide

### 🚀 DevOps

- [CI/CD Workflows](devops/ci-cd-workflows.md) - GitHub Actions automation
- [Git Hooks](devops/git-hooks.md) - Pre-commit security and quality checks
- [Commit Message Enforcement](devops/commit-message-enforcement.md) - Conventional commits guide
- [Codecov Integration](devops/codecov-swift.md) - Code coverage setup

### 🔒 Security

- [Security Policy](SECURITY.md) - Vulnerability reporting and security practices
- [Security Implementation Guide](security/security-implementation-guide.md) - Security controls and tools
- [Semgrep Configuration](security/semgrep.md) - Static analysis setup
- [Snyk Integration](security/snyk-integration.md) - Dependency scanning
- [SSDLC Case Study](security/ssdlc-case-study.md) - Secure development lifecycle implementation

### 📋 Project Management

- [Product Requirements](PRD.md) - Product specification and features
- [Technical Requirements](REQUIREMENTS.md) - Technical specifications
- [Quality Assurance](QA.md) - QA processes and security dashboard
- [Contributors Guide](CONTRIBUTORS.md) - How to contribute
- [Changelog](CHANGELOG.md) - Version history

### 📝 Examples

- [Configuration Examples](examples/config-examples.yaml) - Sample configuration files
- [Configuration Schema](examples/config-schema.json) - JSON schema for validation

### 📦 Archive

- [Feature Power Monitoring PR](archive/pr.feature-power-monitoring.md) - Documentation reorganization and test fixes
- [POC Findings](archive/poc-findings-archive.md) - Proof of concept results
- [Power Detection PR](archive/pr.proto-power-detect.md) - Power monitoring implementation
- [Setup Project PR](archive/pr.setup-project-repo.md) - Initial setup documentation

## 🎯 Quick Links

### For Users

1. Start with the [Product Requirements](PRD.md)
2. Review [Security Policy](SECURITY.md)
3. Check [Troubleshooting](maintainers/troubleshooting.md) for common issues

### For Developers

1. Read [Architecture Overview](architecture/architecture-overview.md)
2. Follow [Building and Running](maintainers/building-and-running.md)
3. Set up [Git Hooks](devops/git-hooks.md)
4. Review [Testing Guide](maintainers/testing-guide.md)

### For Contributors

1. Read [Contributors Guide](CONTRIBUTORS.md)
2. Understand [Commit Message Enforcement](devops/commit-message-enforcement.md)
3. Review [Security Implementation Guide](security/security-implementation-guide.md)
4. Check [CI/CD Workflows](devops/ci-cd-workflows.md)

## 📊 Documentation Standards

- All documentation is written in Markdown
- Diagrams use Mermaid for maintainability
- Code examples include language hints for syntax highlighting
- Internal links use relative paths
- External links include descriptive text

## 🔄 Keeping Documentation Updated

Documentation is a living part of the project. When making changes:

1. Update relevant documentation alongside code changes
2. Ensure all links remain valid
3. Add new documentation to this index
4. Follow the existing structure and formatting

## 💡 Need Help?

- **Found an issue?** Check [Troubleshooting](maintainers/troubleshooting.md)
- **Want to contribute?** See [Contributors Guide](CONTRIBUTORS.md)
- **Security concern?** Follow [Security Policy](SECURITY.md)
- **General questions?** Open a GitHub issue
