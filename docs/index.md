# MagSafe Guard Documentation

Welcome to the MagSafe Guard documentation. This guide will help you understand, build, and contribute to the project.

![MagSafe Guard Demo](assets/magsafe-guard.gif)

## 📚 Documentation Index

### 🏗️ Architecture

- [Architecture Overview](architecture/architecture-overview) - System design and C4 diagrams
- [Power Monitor Service Guide](architecture/power-monitor-service-guide) - Core power detection service
- [Menu Bar App Guide](architecture/menu-bar-app-guide) - macOS menu bar implementation
- [Menu Bar Design Guide](architecture/menu-bar-design-guide) - UI/UX design principles
- [Demo Window Guide](architecture/demo-window-guide) - Testing interface documentation
- [Authentication Flow Design](architecture/auth-flow-design) - Security authentication patterns

### 🔧 Development

- [Building and Running](maintainers/building-and-running) - Build instructions and development setup
- [Testing Guide](maintainers/testing-guide) - Test strategy and implementation
- [Troubleshooting](maintainers/troubleshooting) - Common issues and solutions
- [Figma Integration](maintainers/figma) - Design collaboration guide

### 🚀 DevOps

- [CI/CD Workflows](devops/ci-cd-workflows) - GitHub Actions automation
- [Git Hooks](devops/git-hooks) - Pre-commit security and quality checks
- [Commit Message Enforcement](devops/commit-message-enforcement) - Conventional commits guide
- [Codecov Integration](devops/codecov-swift) - Code coverage setup

### 🔒 Security

- [Security Policy](SECURITY) - Vulnerability reporting and security practices
- [Security Implementation Guide](security/security-implementation-guide) - Security controls and tools
- [Semgrep Configuration](security/semgrep) - Static analysis setup
- [Snyk Integration](security/snyk-integration) - Dependency scanning
- [SSDLC Case Study](security/ssdlc-case-study) - Secure development lifecycle implementation

### 📋 Project Management

- [Product Requirements](PRD) - Product specification and features
- [Technical Requirements](REQUIREMENTS) - Technical specifications
- [Quality Assurance](QA) - QA processes and security dashboard
- [Contributors Guide](CONTRIBUTORS) - How to contribute
- [Changelog](CHANGELOG) - Version history

### 📝 Examples

- [Configuration Examples](examples/config-examples.yaml) - Sample configuration files
- [Configuration Schema](examples/config-schema.json) - JSON schema for validation

### 📦 Archive

- [Feature Power Monitoring PR](archive/pr.feature-power-monitoring) - Documentation reorganization and test fixes
- [POC Findings](archive/poc-findings-archive) - Proof of concept results
- [Power Detection PR](archive/pr.proto-power-detect) - Power monitoring implementation
- [Setup Project PR](archive/pr.setup-project-repo) - Initial setup documentation

## 🎯 Quick Links

### For Users

1. Start with the [Product Requirements](PRD)
2. Review [Security Policy](SECURITY)
3. Check [Troubleshooting](maintainers/troubleshooting) for common issues

### For Developers

1. Read [Architecture Overview](architecture/architecture-overview)
2. Follow [Building and Running](maintainers/building-and-running)
3. Set up [Git Hooks](devops/git-hooks)
4. Review [Testing Guide](maintainers/testing-guide)

### For Contributors

1. Read [Contributors Guide](CONTRIBUTORS)
2. Understand [Commit Message Enforcement](devops/commit-message-enforcement)
3. Review [Security Implementation Guide](security/security-implementation-guide)
4. Check [CI/CD Workflows](devops/ci-cd-workflows)

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

- **Found an issue?** Check [Troubleshooting](maintainers/troubleshooting)
- **Want to contribute?** See [Contributors Guide](CONTRIBUTORS)
- **Security concern?** Follow [Security Policy](SECURITY)
- **General questions?** Open a GitHub issue
