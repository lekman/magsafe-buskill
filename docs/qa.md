# Quality Assurance Dashboard

## 🎯 Quick Links to Analysis Tools

| Tool                | Purpose                  | Dashboard Link                                                                             |
| ------------------- | ------------------------ | ------------------------------------------------------------------------------------------ |
| **GitHub Security** | GHAS, CodeQL, Dependabot | [→ Security Overview](https://github.com/lekman/magsafe-buskill/security)                  |
| **Semgrep**         | SAST Analysis            | [→ Semgrep Dashboard](https://semgrep.dev/orgs/-/projects)                                 |
| **Actions**         | CI/CD Workflows          | [→ Actions Dashboard](https://github.com/lekman/magsafe-buskill/actions)                   |
| **Insights**        | Repository Analytics     | [→ Insights](https://github.com/lekman/magsafe-buskill/pulse)                              |
| **Code Scanning**   | Security Alerts          | [→ Code Scanning Alerts](https://github.com/lekman/magsafe-buskill/security/code-scanning) |
| **Dependabot**      | Dependency Updates       | [→ Dependabot Alerts](https://github.com/lekman/magsafe-buskill/security/dependabot)       |

## 📊 Project Status Overview

[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/lekman/magsafe-buskill/security.yml?branch=main&label=Security%20Scan)](https://github.com/lekman/magsafe-buskill/actions/workflows/security.yml)
[![Release Please](https://img.shields.io/github/actions/workflow/status/lekman/magsafe-buskill/release-please.yml?branch=main&label=Release)](https://github.com/lekman/magsafe-buskill/actions/workflows/release-please.yml)
[![License](https://img.shields.io/github/license/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/blob/main/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/lekman/magsafe-buskill?include_prereleases)](https://github.com/lekman/magsafe-buskill/releases)

## 🔒 Security Status

### GitHub Advanced Security (GHAS)

| Feature               | Status                                                                                                                                                                                | Details                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **CodeQL Analysis**   | [![CodeQL](https://img.shields.io/github/actions/workflow/status/lekman/magsafe-buskill/security.yml?label=CodeQL)](https://github.com/lekman/magsafe-buskill/security/code-scanning) | [View Alerts →](https://github.com/lekman/magsafe-buskill/security/code-scanning)     |
| **Secret Scanning**   | [![Secrets](https://img.shields.io/badge/Secret%20Scanning-Enabled-green)](https://github.com/lekman/magsafe-buskill/security/secret-scanning)                                        | [View Secrets →](https://github.com/lekman/magsafe-buskill/security/secret-scanning)  |
| **Dependency Review** | [![Dependencies](https://img.shields.io/badge/Dependency%20Review-Active-green)](https://github.com/lekman/magsafe-buskill/network/dependencies)                                      | [View Dependencies →](https://github.com/lekman/magsafe-buskill/network/dependencies) |

### Semgrep Analysis

[![Semgrep](https://img.shields.io/badge/Semgrep-Enabled-green)](https://semgrep.dev)

[View Dashboard →](https://semgrep.dev/orgs/-/projects) | [Setup Guide →](./semgrep.md)

### Third-Party Security Tools

| Tool               | Status                                                                                                                                                                                     | Dashboard                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| **Snyk** (Free for OSS) | [![Known Vulnerabilities](https://snyk.io/test/github/lekman/magsafe-buskill/badge.svg)](https://snyk.io/test/github/lekman/magsafe-buskill)                                               | [Snyk Dashboard →](https://app.snyk.io) • [Setup →](./snyk-integration.md) |
| **Libraries.io**   | [![Dependencies](https://img.shields.io/librariesio/github/lekman/magsafe-buskill)](https://libraries.io/github/lekman/magsafe-buskill)                                                    | [View Analysis →](https://libraries.io/github/lekman/magsafe-buskill)     |
| **OSSF Scorecard** | [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/lekman/magsafe-buskill/badge)](https://api.securityscorecards.dev/projects/github.com/lekman/magsafe-buskill) | [View Report →](https://deps.dev/project/github/lekman%2Fmagsafe-buskill) |

## 🎨 Code Quality

### Analysis Tools

| Tool             | Status                                                                                                              | Dashboard                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **Code Climate** | [![Maintainability](https://img.shields.io/badge/Maintainability-Setup%20Required-yellow)](https://codeclimate.com) | [Setup →](https://codeclimate.com/github/lekman/magsafe-buskill) |
| **Codecov**      | [![codecov](https://img.shields.io/badge/Coverage-Pending-yellow)](https://codecov.io)                              | [Setup →](https://codecov.io/gh/lekman/magsafe-buskill)          |
| **SonarCloud**   | [![SonarCloud](https://img.shields.io/badge/SonarCloud-Setup%20Required-yellow)](https://sonarcloud.io)             | [Setup →](https://sonarcloud.io/projects/create)                 |

### Language & Platform

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2011.0%2B-blue.svg)](https://developer.apple.com/macos/)
[![SwiftLint](https://img.shields.io/badge/SwiftLint-Enabled-green)](https://github.com/realm/SwiftLint)

## 🔨 Build & Test Status

### CI/CD Workflows

| Workflow           | Status                                                                                                                                                                                                                  | Details                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Security Scan**  | [![Security](https://img.shields.io/github/actions/workflow/status/lekman/magsafe-buskill/security.yml?branch=main&label=Security)](https://github.com/lekman/magsafe-buskill/actions/workflows/security.yml)           | [View Runs →](https://github.com/lekman/magsafe-buskill/actions/workflows/security.yml)       |
| **Release Please** | [![Release](https://img.shields.io/github/actions/workflow/status/lekman/magsafe-buskill/release-please.yml?branch=main&label=Release)](https://github.com/lekman/magsafe-buskill/actions/workflows/release-please.yml) | [View Runs →](https://github.com/lekman/magsafe-buskill/actions/workflows/release-please.yml) |
| **Security Audit** | [![Audit](https://img.shields.io/badge/Security%20Audit-Manual-blue)](https://github.com/lekman/magsafe-buskill/actions/workflows/security-audit.yml)                                                                   | [Run Audit →](https://github.com/lekman/magsafe-buskill/actions/workflows/security-audit.yml) |

### Workflow Analytics

[View All Workflows →](https://github.com/lekman/magsafe-buskill/actions) | [Workflow Insights →](https://github.com/lekman/magsafe-buskill/actions/workflows)

## 📚 Documentation

[![Documentation](https://img.shields.io/badge/Docs-GitHub%20Pages-blue)](https://lekman.github.io/magsafe-buskill)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/lekman/magsafe-buskill/blob/main/CONTRIBUTORS.md)
[![Contributors](https://img.shields.io/github/contributors/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/graphs/contributors)

## Project Metrics

### Activity

[![GitHub last commit](https://img.shields.io/github/last-commit/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/commits/main)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/graphs/commit-activity)
[![GitHub issues](https://img.shields.io/github/issues/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/lekman/magsafe-buskill)](https://github.com/lekman/magsafe-buskill/pulls)

### Community

[![GitHub stars](https://img.shields.io/github/stars/lekman/magsafe-buskill?style=social)](https://github.com/lekman/magsafe-buskill/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/lekman/magsafe-buskill?style=social)](https://github.com/lekman/magsafe-buskill/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/lekman/magsafe-buskill?style=social)](https://github.com/lekman/magsafe-buskill/watchers)

## Setting Up Additional Badges

### 1. Semgrep Badge

1. Go to [semgrep.dev](https://semgrep.dev)
2. Navigate to your project dashboard
3. Click on "Settings" → "Badges"
4. Choose badge style and copy markdown

### 2. Code Coverage Badge

1. Set up coverage reporting in your test workflow
2. Use services like:
   - [Codecov](https://codecov.io)
   - [Coveralls](https://coveralls.io)
   - [Code Climate](https://codeclimate.com)

### 3. Security Badges

- **Snyk**: Sign up at [snyk.io](https://snyk.io) - **Free for open source projects!**
- **LGTM**: Use [lgtm.com](https://lgtm.com) for security analysis
- **WhiteSource**: [whitesourcesoftware.com](https://www.whitesourcesoftware.com)

### 4. Custom Badges

Create custom badges using [shields.io](https://shields.io):

```markdown
![Custom Badge](https://img.shields.io/badge/Security-A+-brightgreen)
![Custom Badge](https://img.shields.io/badge/Code%20Quality-Excellent-blue)
```

## Automation

To keep badges updated:

1. Most badges auto-update based on GitHub data
2. For manual badges, update during release process
3. Consider adding badge status to release checklist

## Badge Guidelines

- **Keep it relevant**: Only show badges that provide value
- **Group logically**: Security, Quality, Build, etc.
- **Update regularly**: Remove outdated or broken badges
- **Link properly**: Ensure badges link to meaningful destinations
- **Cache considerations**: Some badges cache for performance
