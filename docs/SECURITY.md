# Security Policy

## Supported Versions

MagSafe Guard is currently in pre-release development. Security updates will be provided for:

| Version | Supported          |
| ------- | ------------------ |
| 0.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of MagSafe Guard seriously. If you discover a security vulnerability, please follow these steps:

### 1. Do NOT Create a Public Issue

Security vulnerabilities should **never** be reported through public GitHub issues.

### 2. Report Privately

Please report security vulnerabilities by emailing: [security@lekman.com](mailto:security@lekman.com)

Include the following information:

- Type of vulnerability
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the vulnerability

### 3. Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 5 business days
- **Resolution Target**:
  - Critical: 7 days
  - High: 14 days
  - Medium: 30 days
  - Low: 60 days

## Security Measures

### Code Security

- All code is open source for transparency
- No telemetry or data collection
- Local processing only
- Secure credential storage using macOS Keychain

### Authentication

- TouchID/password required for all security state changes
- No keyboard shortcuts for security operations
- Authentication cannot be disabled
- Maximum 3 failed attempts before cooldown

### Distribution Security

- Code signing with Developer ID (planned)
- Notarization for Gatekeeper (planned)
- SHA-256 checksums for releases
- GPG signed commits and tags

## Security Best Practices for Contributors

1. **Never commit secrets**: API keys, tokens, or passwords
2. **Use secure coding practices**: Input validation, secure defaults
3. **Follow principle of least privilege**: Request only necessary permissions
4. **Test security features**: Ensure authentication works correctly
5. **Review dependencies**: Check for known vulnerabilities

## Secure Software Development Lifecycle (SSDLC)

### Security Toolchain

We implement defense-in-depth using multiple security scanning tools:

#### Static Application Security Testing (SAST)

- **Semgrep**: Security patterns and vulnerability detection
  - OWASP Top 10 coverage
  - Swift-specific security rules
  - Custom rules for macOS security
- **CodeQL**: GitHub's semantic code analysis
  - Query-based vulnerability detection
  - Data flow analysis
  - macOS-specific queries

#### Software Composition Analysis (SCA)

- **Snyk**: Dependency vulnerability scanning
  - Real-time vulnerability database
  - License compliance checking
  - Automated fix PRs
- **Dependabot**: GitHub's dependency updates
  - Security updates prioritized
  - Automated pull requests
- **OSSF Scorecard**: Supply chain security scoring
- **SBOM (Software Bill of Materials)**: Supply chain transparency
  - SPDX 2.3 format for compliance
  - Generated with every release
  - Tracks all dependencies

#### Secret Scanning

- **GitHub Secret Scanning**: Automated secret detection
- **TruffleHog**: Git history scanning
- **Pre-commit hooks**: Local secret prevention

#### Continuous Security

- **Branch protection**: Required security checks
- **SARIF integration**: Unified security dashboard
- **Automated security workflows**: Every PR and commit

### Security Frameworks & Standards

#### OWASP Guidelines

- **OWASP Top 10**: Addressed through Semgrep rules
- **OWASP MASVS**: Mobile Application Security Verification Standard
  - Applied to macOS desktop context
  - Focus on authentication, crypto, and storage
- **OWASP Secure Coding Practices**: Integrated in development

#### Apple Platform Security

- **macOS Security Guide**: Following Apple's best practices
- **Secure Coding Guide**: Apple's secure development guidelines
- **Privacy by Design**: Local-only processing, no telemetry

#### Industry Standards

- **CIS Controls**: Implementing applicable controls
- **NIST Cybersecurity Framework**: Risk-based approach
- **ISO 27001 Principles**: Information security management

### Security Development Practices

1. **Threat Modeling**
   - STRIDE methodology for threat identification
   - Attack surface minimization
   - Regular security reviews

2. **Secure Design Principles**
   - Principle of least privilege
   - Defense in depth
   - Fail secure defaults
   - Complete mediation

3. **Security Testing**
   - Automated security scans on every commit
   - Manual security review for releases
   - Penetration testing (planned)

4. **Vulnerability Management**
   - 48-hour response SLA
   - CVSS scoring for prioritization
   - Coordinated disclosure process

### Compliance & Auditing

- **Security event logging**: Comprehensive audit trail
- **Change management**: All changes reviewed and tested
- **Access control**: Repository permissions management
- **Incident response**: Defined security incident process
- **Software Bill of Materials (SBOM)**: 
  - Generated for every release in SPDX 2.3 format
  - Provides complete dependency transparency
  - Enables vulnerability tracking and license compliance
  - Located at `/sbom.spdx` in repository root

## Security Features

MagSafe Guard includes several security features:

- **Power monitoring**: Detects unauthorized device removal
- **Authentication**: TouchID/password for arm/disarm
- **Grace period**: Prevents false positives
- **Secure configuration**: Sensitive data in Keychain
- **Audit logging**: Security events are logged
- **Code signing**: Developer ID signing (planned)
- **Notarization**: Apple notarization (planned)

## Disclosure Policy

When we receive a security report, we will:

1. Confirm the vulnerability
2. Determine the impact and severity
3. Develop and test a fix
4. Release the fix with appropriate disclosure
5. Credit the reporter (unless anonymity is requested)

## Security Advisories

Security advisories will be published through:

- GitHub Security Advisories
- Release notes
- Security mailing list (if established)

## Contact

For security concerns, contact: [security@lekman.com](mailto:security@lekman.com)
For general issues, use GitHub Issues.

---

This security policy is adapted from standard security practices for open source projects.
