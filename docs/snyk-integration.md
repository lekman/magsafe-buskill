# Snyk Integration Guide

## Overview

Snyk provides free vulnerability scanning for open source projects. This guide walks through integrating Snyk with MagSafe Guard.

## Why Snyk?

- **Free for Open Source**: Unlimited scans for public repositories
- **Comprehensive Scanning**: Dependencies, containers, IaC, and code
- **Automated Fix PRs**: Snyk creates PRs to fix vulnerabilities
- **License Compliance**: Detects problematic licenses
- **Swift Support**: Native support for Swift Package Manager

## Qualifying for Free Open Source Tier

### Requirements

1. **Public Repository**: Must be publicly accessible on GitHub
2. **Open Source License**: MIT, Apache, GPL, etc. (✓ We have MIT)
3. **Not Corporate Backed**: Individual/community projects qualify
4. **Attribution**: Include Snyk badge and link in README (✓ Added)

### What's Included

- **Unlimited testing** for open source projects
- **All Snyk products**: Open Source, Code, Container, IaC
- **Automated fix PRs**
- **License scanning**
- **No usage limits**

## Setup Instructions

### 1. Create Free Snyk Account

1. Visit [snyk.io](https://snyk.io)
2. Click "Sign up for free"
3. Choose "Sign up with GitHub" (recommended)
4. Authorize Snyk to access your GitHub account

### 2. Import Repository

1. In Snyk dashboard, click "Add project"
2. Select "GitHub"
3. Find `lekman/magsafe-buskill` in your repository list
4. Click "Add selected repositories"

### 3. Configure Project Settings

1. Go to project settings in Snyk
2. Enable these features:
   - **Automatic fix PRs**: Yes
   - **Scan frequency**: Daily
   - **Fail PRs on high severity**: Yes
   - **License scanning**: Enabled

### 4. Get Your Badge

1. In project overview, click "Settings"
2. Click "Badge"
3. Copy the markdown code
4. The badge is already added to `docs/qa.md`

### 5. GitHub Integration (Optional)

For PR checks and inline comments:

1. Install Snyk GitHub App:

   ```text
   https://github.com/apps/snyk
   ```

2. Configure for your repository

3. Add to `.github/workflows/security.yml`:

   ```yaml
   snyk:
     name: Snyk Security
     runs-on: ubuntu-latest
     steps:
       - uses: actions/checkout@v4
       - name: Run Snyk to check for vulnerabilities
         uses: snyk/actions/swift@master
         env:
           SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
         with:
           args: --severity-threshold=high
   ```

### 6. Add Snyk Token (If using workflow)

1. In Snyk account settings, go to "General"
2. Copy your API token
3. In GitHub repository settings:
   - Go to Settings → Secrets → Actions
   - Add new secret: `SNYK_TOKEN`
   - Paste your token

## What Snyk Scans

### Dependencies

- Swift Package Manager dependencies
- Transitive dependencies
- Known vulnerabilities (CVEs)
- License compliance issues

### Code Security (Snyk Code)

- Security vulnerabilities in Swift code
- Quality issues
- Best practice violations

### Container Scanning

- If we add Docker support later
- Base image vulnerabilities
- Dockerfile best practices

## Understanding Results

### Vulnerability Severity

- **Critical**: Exploit available, fix immediately
- **High**: Serious issue, fix soon
- **Medium**: Fix in next release
- **Low**: Consider fixing

### Fix Strategies

1. **Automatic PRs**: Snyk creates fix PRs
2. **Manual Updates**: Update dependencies yourself
3. **Ignore (with reason)**: For false positives

### License Issues

Common problematic licenses:

- GPL (copyleft)
- AGPL (network copyleft)
- Custom/Unknown licenses

## Integration with Development Workflow

### Pre-commit Scanning

Add to your local workflow:

```bash
# Install Snyk CLI
brew install snyk

# Authenticate
snyk auth

# Test locally
snyk test

# Test with threshold
snyk test --severity-threshold=high
```

### CI/CD Integration

The security workflow runs Snyk on:

- Every push to main
- Every pull request
- Daily scheduled scans

### VS Code Extension

1. Install "Snyk Security" extension
2. Sign in with your Snyk account
3. Get inline vulnerability warnings

## Best Practices

### Regular Monitoring

- Check Snyk dashboard weekly
- Review and merge fix PRs promptly
- Update dependencies regularly

### False Positives

If Snyk reports a false positive:

1. Click "Ignore this issue"
2. Select appropriate reason:
   - Not vulnerable (explain why)
   - No upgrade available
   - Temporary ignore (set date)

### Security Policy

Document your security policy:

- Which severities block PRs
- SLA for fixing vulnerabilities
- Process for security updates

## Troubleshooting

### "Repository not found"

- Re-import repository in Snyk
- Check GitHub permissions

### "No manifest files found"

- Ensure Package.swift is present
- Check Snyk supports your package manager

### Badge not updating

- Badges cache for up to 24 hours
- Force refresh: Add `?cacheBust=<timestamp>` to URL

## Cost Considerations

### Free Tier Limits

- **Open Source**: Unlimited
- **Private Repos**: 200 tests/month
- **Team Size**: Up to 5 contributors

### When You Might Need Paid

- Private repository with >200 tests/month
- Advanced reporting features
- Priority support
- Custom policies

## Alternatives to Snyk

If Snyk doesn't meet your needs:

1. **GitHub Dependabot** (free)
   - Basic dependency scanning
   - Integrated with GitHub

2. **WhiteSource Renovate** (free for OSS)
   - Aggressive dependency updates
   - More configuration options

3. **OWASP Dependency Check**
   - Self-hosted option
   - No external service needed

## Conclusion

Snyk provides comprehensive security scanning that complements our existing Semgrep and GitHub Security setup. The free tier is perfect for open source projects like MagSafe Guard.

## Next Steps

1. Sign up for free account
2. Import repository
3. Review initial scan results
4. Merge any fix PRs
5. Add Snyk CLI to local development

## Resources

- [Snyk Documentation](https://docs.snyk.io)
- [Snyk for Swift](https://snyk.io/advisor/swift)
- [Security Best Practices](https://snyk.io/learn)
