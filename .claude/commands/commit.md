# Smart Commit with QA and Security Checks

Analyze changes, create a conventional commit message, run QA checks, and commit if all passes.

## Process

1. **Analyze Changes**
   - Run `git status` to see modified files
   - Run `git diff --cached` to see staged changes
   - Determine commit type and scope

2. **Generate Commit Message**
   - Create conventional commit format: `type(scope): description`
   - If multiple files changed, add detailed list in body
   - Follow conventional commit standards

3. **Pre-Commit Checks**
   - Run `task qa:quick` for fast validation
   - Check for security issues
   - Ensure no secrets or sensitive data

4. **Commit with Hooks**
   - Stage all changes
   - Attempt commit
   - If hooks fail, fix issues automatically

5. **Handle Failures**
   - If commit hooks fail, analyze error
   - Run appropriate fixes:
     - Linting: `task qa:fix`
     - Security: Check blocked patterns
     - Tests: Fix failing tests
   - Retry commit after fixes

## Execution Steps

### 1. Check Current State

```bash
# Check what's changed
git status --porcelain

# Check if we have staged changes
git diff --cached --name-only

# If nothing staged, stage all changes
git add -A
```

### 2. Analyze Changes for Commit Type

Determine type based on changes:
- **feat**: New features or functionality
- **fix**: Bug fixes
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, semicolons, etc)
- **refactor**: Code changes that neither fix bugs nor add features
- **test**: Adding or updating tests
- **chore**: Maintenance tasks, dependency updates
- **perf**: Performance improvements
- **ci**: CI/CD changes
- **build**: Build system changes

### 3. Generate Commit Message

For single file:
```
type(scope): concise description
```

For multiple files:
```
type(scope): concise description

- path/to/file1: what changed
- path/to/file2: what changed
- path/to/file3: what changed
```

### 4. Run QA Checks

```bash
# Quick QA check
task qa:quick

# If fails, run full QA
task qa
```

### 5. Attempt Commit

```bash
# Commit with generated message
git commit -m "$(cat commit_message.txt)"
```

### 6. Handle Hook Failures

If commit fails due to hooks:

```bash
# Check which hook failed
# Common failures:

# 1. Linting issues
task qa:fix
git add -A

# 2. Commit message format
# Fix message and retry

# 3. Security issues
task security:secrets
# Remove any found secrets

# 4. Test failures
task test
# Fix failing tests

# Retry commit
git commit -m "$(cat commit_message.txt)"
```

## Security Checks

Before committing, ensure:
1. No hardcoded secrets or API keys
2. No sensitive file paths or URLs
3. No debugging code with sensitive data
4. No TODO comments with security implications

## Best Practices

1. **Atomic Commits**: Each commit should be a single logical change
2. **Clear Messages**: Commit messages should explain WHY, not just what
3. **Test First**: Ensure tests pass before committing
4. **Security First**: Never commit sensitive data
5. **Clean History**: Use conventional commits for clear history

## Example Workflow

```bash
# 1. Stage changes
git add -A

# 2. Generate commit message based on changes
# Example: "feat(auth): add biometric authentication support"

# 3. Run QA
task qa:quick

# 4. If QA passes, commit
git commit -m "feat(auth): add biometric authentication support

- Sources/MagSafeGuard/Services/AuthenticationService.swift: add biometric auth
- Sources/MagSafeGuard/Settings/SecuritySettings.swift: add toggle for biometric
- Tests/MagSafeGuardTests/AuthenticationTests.swift: add biometric tests"

# 5. If hooks fail, fix and retry
task qa:fix
git add -A
git commit -m "..."
```

## Troubleshooting

### Commit Message Rejected
- Check format: `type(scope): description`
- Ensure type is valid (feat, fix, docs, etc.)
- Keep subject line under 72 characters
- Don't end with period

### Linting Failures
- Run `task swift:lint:fix`
- Run `task markdown:lint:fix`
- Stage fixed files and retry

### Test Failures
- Run `task test` to see failures
- Fix failing tests
- Consider if changes broke existing functionality

### Security Blocks
- Check for API keys, passwords, tokens
- Remove any `.env` files from staging
- Use environment variables instead

## Priority Order

1. **Security Issues** - Must fix immediately
2. **Test Failures** - Must fix before commit
3. **Linting Errors** - Auto-fix when possible
4. **Code Smells** - Fix if critical
5. **Documentation** - Update if needed