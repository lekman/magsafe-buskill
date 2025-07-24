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

Please report security vulnerabilities by emailing: [YOUR-SECURITY-EMAIL]

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

## Security Features

MagSafe Guard includes several security features:

- **Power monitoring**: Detects unauthorized device removal
- **Authentication**: TouchID/password for arm/disarm
- **Grace period**: Prevents false positives
- **Secure configuration**: Sensitive data in Keychain
- **Audit logging**: Security events are logged

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

For security concerns, contact: [YOUR-SECURITY-EMAIL]
For general issues, use GitHub Issues.

---

This security policy is adapted from standard security practices for open source projects.