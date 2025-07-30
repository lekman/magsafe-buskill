# Fork Pull Request Security Policy

## Overview

This document outlines security measures for handling pull requests from forks to prevent secret leakage and malicious actions.

## Key Security Principles

### 1. **No Secrets in Fork PR Workflows**

- Fork PRs run with `pull_request` event (not `pull_request_target`)
- No access to repository secrets
- Read-only permissions by default

### 2. **Manual Approval Required**

- Use GitHub's "Approve and run workflows" feature
- Maintainers must review code before workflows run
- First-time contributors always require approval

### 3. **Workflow Isolation**

```yaml
# Safe for fork PRs - no secrets
on:
  pull_request:
    types: [opened, synchronize]

# Dangerous for fork PRs - has secrets
on:
  pull_request_target:  # Runs in base repo context
  push:                  # Only runs on base repo
```

## Implementation Guidelines

### Safe Workflow Pattern

```yaml
name: PR Tests (Fork Safe)
on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
      - run: npm test
      # No secrets available here
```

### Dangerous Workflow Pattern (Avoid)

```yaml
name: PR Deploy (DANGEROUS)
on:
  pull_request_target: # Runs with full permissions!

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
        with:
          ref: ${{ github.event.pull_request.head.sha }} # Checks out fork code!
      - run: ./deploy.sh # Fork code has access to secrets!
        env:
          API_KEY: ${{ secrets.API_KEY }} # LEAKED!
```

## Security Checklist

- [ ] Fork PRs use `pull_request` event, not `pull_request_target`
- [ ] No secrets exposed to fork PR workflows
- [ ] Manual approval required for first-time contributors
- [ ] Code review before running workflows with elevated permissions
- [ ] Separate workflows for CI (safe) vs CD (dangerous)
- [ ] Pin all third-party actions to specific SHAs
- [ ] Use GITHUB_TOKEN with minimal permissions
- [ ] Enable "Restrict who can dismiss pull request reviews"
- [ ] Enable branch protection rules

## Additional Protections

### 1. Environment Protection Rules

```yaml
jobs:
  deploy:
    environment: production # Requires approval
    steps:
      - run: ./deploy.sh
```

### 2. CODEOWNERS File

```text
# .github/CODEOWNERS
.github/workflows/ @security-team @maintainers
```

### 3. Workflow Permissions

```yaml
permissions:
  contents: read # Minimal permissions
  pull-requests: write # Only if needed
```

## Responding to Security Incidents

1. Immediately revoke compromised secrets
2. Review workflow run logs for unauthorized access
3. Audit all recent PR merges
4. Update security policies based on lessons learned

## References

- [GitHub Security Hardening Guide](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Keeping secrets secret](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Security considerations for pull_request_target](https://securitylab.github.com/research/github-actions-preventing-pwn-requests/)
