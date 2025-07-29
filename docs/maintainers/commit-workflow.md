# Commit Workflow Guide

This guide describes the automated commit workflow using the `/commit` slash command.

## Overview

The `/commit` command provides an intelligent way to create conventional commits with automatic QA and security checks.

## Features

- **Automatic Commit Type Detection**: Analyzes changes to determine the appropriate commit type
- **Conventional Commit Format**: Follows the conventional commits specification
- **Multi-file Support**: Adds detailed change descriptions for multiple files
- **QA Integration**: Runs quality checks before committing
- **Security Validation**: Ensures no secrets or sensitive data are committed
- **Hook Failure Recovery**: Automatically fixes common issues and retries

## Usage

Simply type `/commit` in Claude Code and the command will:

1. Analyze all staged and unstaged changes
2. Generate an appropriate commit message
3. Run QA checks
4. Attempt to commit
5. Fix any issues and retry if needed

## Example Workflow

```bash
# Make some changes
vim Sources/MagSafeGuard/SomeFile.swift

# Use the commit command
/commit

# The command will:
# 1. Stage changes
# 2. Generate message like "fix(auth): resolve login timeout issue"
# 3. Run task qa:quick
# 4. Commit if all passes
```

## Commit Message Format

The command generates messages following this format:

```
type(scope): subject

- file1: what changed
- file2: what changed
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Test additions/changes
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes
- `build`: Build system changes

## Security First

The command ensures:

- No API keys or secrets
- No sensitive file paths
- No debug code with passwords
- No private data in commits

## Integration with QA

Before committing, the command runs:

- SwiftLint checks
- Markdown linting
- Security scanning
- Test verification

If any check fails, it automatically attempts to fix the issues.

## Best Practices

1. **Review Generated Message**: Always review the auto-generated commit message
2. **Keep Commits Atomic**: One logical change per commit
3. **Write Clear Descriptions**: Ensure the message explains WHY, not just what
4. **Security Conscious**: Never override security warnings

## Troubleshooting

### Commit Rejected by Hooks

The command will automatically:

1. Identify which hook failed
2. Run appropriate fixes
3. Re-stage changes
4. Retry the commit

### Common Fixes

- **Linting**: Runs `task qa:fix`
- **Tests**: Identifies and helps fix failing tests
- **Security**: Removes detected secrets
- **Format**: Fixes commit message format

## Related Commands

- `/qa` - Run full quality assurance checks
- `/pr` - Create a pull request
- `/task` - Run specific tasks

---

This workflow ensures high-quality, secure commits that follow project standards.
