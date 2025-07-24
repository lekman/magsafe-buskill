# Semgrep Security Scanning

## Overview

Semgrep is a static analysis tool that helps identify security vulnerabilities, bugs, and code quality issues in the MagSafe Guard codebase. It's integrated into our CI/CD pipeline to automatically scan code on every push and pull request.

## Purpose

### Why Semgrep?

1. **Security First**: MagSafe Guard is a security application, so our code must be secure
2. **Swift Support**: Native support for Swift security patterns
3. **Zero False Positives**: Focuses on high-confidence findings
4. **Developer Friendly**: Clear explanations and fix suggestions
5. **Open Source Friendly**: Free tier suitable for open source projects

### What It Scans For

- **Security Vulnerabilities**: SQL injection, XSS, command injection, etc.
- **Secrets Detection**: API keys, passwords, tokens accidentally committed
- **OWASP Top 10**: Common security vulnerabilities
- **Swift-Specific Issues**: Memory leaks, unsafe operations, etc.
- **Best Practices**: Code quality and security patterns

## Setup Instructions

### 1. Create Semgrep Account

1. Visit [semgrep.dev](https://semgrep.dev)
2. Sign up using GitHub (recommended) or email
3. Authorize Semgrep to access your repositories

### 2. Connect Repository

1. In Semgrep dashboard, go to "Projects"
2. Click "Add repository"
3. Select `magsafe-buskill` from your repository list
4. Semgrep will automatically start scanning

### 3. Generate App Token

1. Navigate to **Settings** → **Tokens**
2. Click **"Create new token"**
3. Name it: "GitHub Actions - MagSafe Guard"
4. Select "CI" permissions
5. Copy the generated token immediately

### 4. Add Token to GitHub

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Name: `SEMGREP_APP_TOKEN`
4. Value: Paste the copied token
5. Click **"Add secret"**

## Configuration

### Workflow Integration

Semgrep is integrated in `.github/workflows/security.yml`:

```yaml
- name: Run Semgrep
  uses: returntocorp/semgrep-action@v1
  with:
    config: >-
      p/security-audit    # General security rules
      p/secrets          # Secret detection
      p/owasp-top-ten    # OWASP vulnerabilities
      p/swift            # Swift-specific rules
  env:
    SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

### Rule Sets Used

1. **p/security-audit**: Comprehensive security checks
2. **p/secrets**: Detects hardcoded secrets and credentials
3. **p/owasp-top-ten**: OWASP Top 10 vulnerability patterns
4. **p/swift**: Swift-specific security and quality rules

### Custom Rules (Future)

Custom rules can be added in `.semgrep.yml`:

```yaml
rules:
  - id: magsafe-guard-auth-check
    pattern: |
      LocalAuthentication.authenticate(...)
    message: Ensure authentication includes proper error handling
    severity: WARNING
```

## Interpreting Results

### Severity Levels

- **ERROR**: Critical security issues - must fix before merge
- **WARNING**: Potential issues - should review and fix
- **INFO**: Best practice suggestions - optional improvements

### Example Findings

1. **Hardcoded Secrets**
   ```
   Found hardcoded API key in Config.swift:12
   Severity: ERROR
   Fix: Move to environment variable or keychain
   ```

2. **Shell Injection**
   ```
   User input passed to shell command in Utils.swift:45
   Severity: ERROR
   Fix: Sanitize input or use safer API
   ```

### False Positives

If Semgrep reports a false positive:

1. Review the finding carefully
2. If confirmed false positive, add inline comment:
   ```swift
   // nosemgrep: rule-id
   let safeCode = "This is actually safe"
   ```

## Dashboard Features

### Pull Request Integration

- Automated comments on PRs with findings
- Inline code suggestions
- Links to remediation guides

### Metrics and Trends

- Security score over time
- Most common vulnerability types
- Fix rate tracking
- Developer leaderboards

## Best Practices

### For Developers

1. **Run Locally**: Install Semgrep CLI for pre-commit scanning
   ```bash
   brew install semgrep
   semgrep --config=auto .
   ```

2. **Fix Immediately**: Address security findings before PR review

3. **Learn from Findings**: Each finding includes educational content

### For Reviewers

1. Check Semgrep status in PR checks
2. Review any suppressed findings
3. Ensure security findings are addressed

## Troubleshooting

### Common Issues

1. **"No SEMGREP_APP_TOKEN"**
   - Ensure secret is added to repository
   - Check secret name matches exactly

2. **"Repository not found"**
   - Reconnect repository in Semgrep dashboard
   - Ensure Semgrep app has repository access

3. **"Rule not found"**
   - Update to latest Semgrep action version
   - Check rule set names are correct

### Getting Help

- Semgrep Documentation: [semgrep.dev/docs](https://semgrep.dev/docs)
- Rule Registry: [semgrep.dev/r](https://semgrep.dev/r)
- Community: [r2c.dev/slack](https://r2c.dev/slack)

## Security Considerations

### Token Security

- App tokens are scoped to specific repositories
- Rotate tokens periodically (every 90 days)
- Never commit tokens to code
- Use GitHub Secrets for storage

### Data Privacy

- Semgrep only accesses code, not runtime data
- Findings are stored in Semgrep's secure infrastructure
- No code is stored permanently
- Opt-out of telemetry available

## Alternative: Basic Security Scanning

If you prefer not to use Semgrep's cloud service, a basic security workflow is available at `.github/workflows/security-basic.yml` that provides:

- Local secret detection
- Permission checks
- Security TODO scanning
- No external dependencies

However, this lacks:
- Comprehensive rule sets
- Dashboard and metrics
- PR integration
- Automatic updates

## Future Enhancements

1. **Custom Rules**: Add MagSafe Guard-specific security patterns
2. **Pre-commit Hooks**: Local scanning before commit
3. **Security Training**: Use findings for team education
4. **Metrics Integration**: Security KPIs in project dashboard

## Conclusion

Semgrep provides automated security scanning that's essential for a security-focused application like MagSafe Guard. By catching vulnerabilities early in the development process, we maintain the high security standards our users expect.