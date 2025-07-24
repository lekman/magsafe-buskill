# Git Hooks Setup Guide

## Overview

MagSafe Guard uses Git hooks to enforce security best practices and commit standards before code reaches the repository. This ensures consistent code quality and prevents accidental security issues.

## Quick Setup

```bash
# Run the setup script
./scripts/setup-hooks.sh
```

This configures Git to use the hooks in `.githooks/` directory.

## Available Hooks

### 1. Pre-commit Hook

**Purpose**: Prevents committing secrets and runs security scans

**Checks performed**:

- ✅ Hardcoded passwords in Swift files
- ✅ API keys and secrets
- ✅ Private key files (.pem, .key, .p12)
- ✅ Environment files (.env)
- ✅ Semgrep scan (if installed)

**Usage**:

```bash
# Normal commit (runs all checks)
git commit -m "feat: add new feature"

# Skip Semgrep only
SKIP_SEMGREP=1 git commit -m "feat: add new feature"

# Skip all hooks (emergency only!)
git commit --no-verify -m "fix: emergency patch"
```

### 2. Commit Message Hook

**Purpose**: Ensures commits follow Conventional Commits format

**Valid formats**:

```xml
<type>(<scope>): <subject>
<type>: <subject>
```

**Valid types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code restructuring
- `perf`: Performance improvements
- `test`: Test changes
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Maintenance tasks
- `revert`: Reverting commits

**Examples**:

```bash
# ✅ Good commit messages
git commit -m "feat: add TouchID authentication support"
git commit -m "fix(auth): resolve timeout issue in biometric prompt"
git commit -m "docs: update security policy for pre-commit hooks"

# ❌ Bad commit messages
git commit -m "updated files"
git commit -m "Fixed bug"
git commit -m "feat add new feature"  # Missing colon
```

## Installing Semgrep (Optional)

For enhanced security scanning:

```bash
# macOS
brew install semgrep

# Alternative: pip
pip install semgrep

# Verify installation
semgrep --version
```

## Troubleshooting

### "Permission denied" error

```bash
# Fix hook permissions
chmod +x .githooks/*
```

### Hooks not running

```bash
# Verify hooks path
git config core.hooksPath

# Re-run setup
./scripts/setup-hooks.sh
```

### False positives in security scan

If the pre-commit hook flags legitimate code:

1. Review the code to ensure it's not a real security issue
2. If it's a false positive (e.g., example code), you can:
   - Refactor to avoid the pattern
   - Use `--no-verify` for that specific commit
   - Add a comment explaining why it's safe

### Commit message rejected

```bash
# View the exact error
git commit -m "your message" --dry-run

# Common fixes:
# - Add type prefix (feat:, fix:, etc.)
# - Add colon after type
# - Add space after colon
# - Keep first line under 72 characters
```

## Security Considerations

### Why These Hooks?

1. **Pre-commit security scan**: Prevents secrets from entering git history
2. **Conventional commits**: Enables automated versioning and changelog generation
3. **Local execution**: Fast feedback without network dependency

### Important Notes

- Hooks run locally and can be bypassed with `--no-verify`
- CI/CD runs the same checks, so bypassing locally will still fail in PR
- Never commit real secrets, even in examples
- Use environment variables or secure storage for sensitive data

## Team Onboarding

When new developers join:

1. Clone the repository
2. Run `./scripts/setup-hooks.sh`
3. Optionally install Semgrep for enhanced scanning
4. Make a test commit to verify setup

## Customization

### Disable specific checks

Edit `.githooks/pre-commit`:

```bash
# Skip certain file types
if [[ "$file" =~ \.(test|example)\.swift$ ]]; then
    continue
fi
```

### Add custom checks

Add to `.githooks/pre-commit`:

```bash
# Check for console.log statements
if git diff --cached | grep -q "console\.log"; then
    echo "Remove console.log statements"
    exit 1
fi
```

## Best Practices

1. **Run setup on clone**: Make it part of your onboarding checklist
2. **Don't bypass regularly**: If you're using `--no-verify` often, the checks need adjustment
3. **Keep Semgrep updated**: `brew upgrade semgrep` periodically
4. **Report false positives**: Help improve the hooks for the team

## Integration with CI/CD

These hooks complement our CI/CD pipeline:

- **Local hooks**: Fast feedback during development
- **CI/CD checks**: Comprehensive scanning with full rule sets
- **Both required**: Local hooks can be bypassed, CI/CD cannot

The same security checks run in both places, ensuring consistency.
