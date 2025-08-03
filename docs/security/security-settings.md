# Repository Security Settings Checklist

## GitHub Repository Settings

### Actions Settings (Settings → Actions → General)

1. **Fork pull request workflows**

   - ✅ "Require approval for all external collaborators"
   - ❌ Never use "Run workflows from fork pull requests"

2. **Workflow permissions**

   - ✅ "Read repository contents and packages permissions"
   - ✅ "Allow GitHub Actions to create and approve pull requests" (only if needed)

3. **Actions permissions**
   - ✅ "Allow actions created by GitHub"
   - ✅ "Allow actions by Marketplace verified creators"
   - ⚠️ "Allow specified actions and reusable workflows" (specify exact list)

### Branch Protection Rules

1. **Main branch protection**
   - ✅ Require pull request reviews (2+ reviewers)
   - ✅ Dismiss stale pull request approvals
   - ✅ Require review from CODEOWNERS
   - ✅ Restrict who can dismiss reviews
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date
   - ✅ Include administrators

### Secrets Management

1. **Repository Secrets**

   - Use environment-specific secrets
   - Implement secret rotation policy
   - Audit secret access logs regularly

2. **Environment Protection**

   ```test
   Production Environment:
   - Required reviewers: 2
   - Restrict to protected branches
   - Add deployment branch policies
   ```

## Recommended Workflow Structure

```ini
.github/
├── workflows/
│   ├── ci.yml                    # Safe: runs on PR (no secrets)
│   ├── ci-privileged.yml         # Dangerous: runs on push to main only
│   ├── deploy.yml                # Dangerous: manual trigger only
│   └── pull-request-fork-security.yml  # Fork PR validation
├── CODEOWNERS
├── fork-pr-policy.md
└── security-settings.md
```

## Security Tools Integration

### 1. Dependabot Security Updates

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
    reviewers:
      - "@security-team"
```

### 2. Code Scanning

- Enable GitHub Advanced Security (if available)
- Use CodeQL analysis
- Third-party security scanners (Snyk, etc.)

### 3. Secret Scanning

- Enable secret scanning
- Configure custom patterns
- Set up push protection

## Monitoring and Alerts

1. **Audit Log Monitoring**

   - Review workflow runs from forks
   - Monitor secret access patterns
   - Track permission changes

2. **Alerts Configuration**
   - Security advisories
   - Vulnerable dependency alerts
   - Unusual activity notifications
