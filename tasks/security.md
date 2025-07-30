# Security Tasks

This module provides security scanning and vulnerability detection capabilities for the MagSafe Guard project.

## Available Tasks

```bash
task security:           # Show available security tasks
task security:scan       # Run full security scan
task security:secrets    # Check for hardcoded secrets
task security:semgrep    # Run Semgrep security analysis
task security:pin-actions    # Pin GitHub Actions to SHAs
task security:update-pins    # Update pinned action SHAs
task security:check-pins     # Check if all actions are pinned
task security:dependabot     # Setup Dependabot configuration
```

## Task Details

### Full Security Scan (`task security:scan`)

Runs a comprehensive security scan including:

- Secret detection
- Semgrep analysis (if available)
- GitHub Action pin verification

### Secret Detection (`task security:secrets`)

Scans the codebase for potential secrets and sensitive data:

- Passwords in code
- API keys
- Secret tokens
- Private keys
- Bearer tokens

**Patterns checked:**

- `password.*=.*['\"]`
- `api[_-]?key.*=.*['\"]`
- `secret.*=.*['\"]`
- `private[_-]?key`
- `BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY`
- `bearer.*['\"]`

### Semgrep Analysis (`task security:semgrep`)

Runs Semgrep with auto-configured rules for:

- Security vulnerabilities
- Code quality issues
- Best practice violations

**Requirements:**

- Semgrep installed: `brew install semgrep`

### GitHub Actions Security

#### Pin Actions (`task security:pin-actions`)

Pins all GitHub Actions to specific commit SHAs for supply chain security.

**Usage:**

```bash
# Pin all workflows and actions in default directories (.github/workflows and .github/actions)
task security:pin-actions

# Pin a specific workflow file
task security:pin-actions TARGET_PATH=.github/workflows/build-sign.yml

# Pin a specific composite action file
task security:pin-actions TARGET_PATH=.github/actions/cancel-redundant-workflows/action.yml

# Pin only workflows (override default)
task security:pin-actions TARGET_PATH=.github/workflows

# Pin only composite actions (override default)
task security:pin-actions TARGET_PATH=.github/actions
```

**Example transformation:**

```yaml
# Before
uses: actions/checkout@v3

# After
uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608 # v3
```

**Features:**

- Preserves version as comment
- Uses token-based authentication from `.env` file
- Handles rate limiting gracefully
- Skips local actions (starting with `./`)
- Supports both individual files and directories

#### Update Pins (`task security:update-pins`)

Updates pinned actions to latest SHAs while maintaining version tags.

#### Check Pins (`task security:check-pins`)

Verifies all actions are properly pinned. Used in CI/CD pipelines.

### Dependabot Setup (`task security:dependabot`)

Creates Dependabot configuration for automated dependency updates:

- Weekly checks for GitHub Actions
- Weekly checks for Swift packages
- Grouped updates for actions
- Automatic labeling

## Configuration

### GitHub Token

For better API rate limits when pinning actions:

```bash
# Add to .env file
GITHUB_TOKEN=your_github_token_here
```

### Semgrep Configuration

The project uses Semgrep's auto-configuration by default. To customize:

1. Create `.semgrep.yml` in project root
2. Define custom rules
3. Run `task security:semgrep`

## Git Hooks Integration

Security tasks are integrated into git hooks:

### Pre-commit Hook

- Checks for hardcoded secrets
- Detects private key files
- Prevents committing .env files
- Runs Semgrep scan (if installed)

To skip security checks in emergencies:

```bash
git commit --no-verify
```

To skip only Semgrep:

```bash
SKIP_SEMGREP=1 git commit
```

## Best Practices

1. **Always pin actions**: Run `task security:pin-actions` after adding new workflows
2. **Regular updates**: Use `task security:update-pins` weekly for security fixes
3. **Enable Dependabot**: Run `task security:dependabot` for automated updates
4. **Pre-push checks**: Always run `task security:scan` before pushing
5. **Review findings**: Don't ignore security warnings, fix or document exceptions

## Troubleshooting

### GitHub API Rate Limits

If you encounter rate limit errors:

1. Create a [GitHub personal access token](https://github.com/settings/tokens)
2. Add to `.env`: `GITHUB_TOKEN=your_token_here`
3. The task will automatically use it

### Semgrep Not Found

Install Semgrep:

```bash
# macOS
brew install semgrep

# Other platforms
pip install semgrep
```

### False Positives

For false positive secrets:

1. Use environment variables instead
2. If unavoidable, add to `.gitignore`
3. Document in security exceptions

## CI/CD Integration

Security tasks are run automatically in CI:

- Pull requests: `task security:secrets`
- Main branch: `task security:scan`
- Weekly: `task security:update-pins`
