# Commit Message Enforcement

MagSafe Guard enforces commit message standards at multiple levels to ensure consistency and prevent certain words from appearing in the project history.

## Enforcement Levels

### 1. Local Git Hooks (Immediate Feedback)

Located in `.githooks/commit-msg`, these run on your machine:

- ✅ Instant feedback before commit
- ✅ No network required
- ⚠️ Can be bypassed with `--no-verify`
- 📝 Configured via `./scripts/setup-hooks.sh`

### 2. GitHub Actions (Server-Side Enforcement)

The `.github/workflows/commit-message-check.yml` workflow:

- ✅ Cannot be bypassed
- ✅ Runs on all PRs and pushes
- ✅ Blocks merge if checks fail
- ✅ Enforces both format and word blocklist

## Blocked Words

The following words are prohibited in commit messages (case-insensitive):

- `claude`
- `anthropic`
- `co-authored`

## Conventional Commits Format

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

```xml
<type>(<scope>): <subject>
```

Allowed types:

- `feat` - New features
- `fix` - Bug fixes
- `docs` - Documentation
- `style` - Code style/formatting
- `refactor` - Code refactoring
- `perf` - Performance improvements
- `test` - Tests
- `build` - Build system
- `ci` - CI/CD changes
- `chore` - Maintenance
- `revert` - Revert commits

## Branch Protection Setup

To fully enforce these rules, configure branch protection in GitHub:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators
4. Add required status checks:
   - `Validate Commit Messages`

## Fixing Violations

### If local hook blocks your commit

```bash
# Fix the message and try again
git commit -m "feat: proper message without blocked words"
```

### If GitHub Actions blocks your PR

```bash
# View which commits have issues
git log --oneline origin/main..HEAD

# Interactive rebase to fix commit messages
git rebase -i origin/main

# Change 'pick' to 'reword' for problematic commits
# Save and edit each commit message

# Force push the cleaned history
git push --force-with-lease
```

## Why These Restrictions?

1. **Professional repository**: Maintains a clean, professional git history
2. **Automated tooling**: Conventional commits enable automated versioning and changelogs
3. **Consistency**: Ensures all contributors follow the same standards
4. **Legal/licensing**: Prevents attribution issues

## Adding Exceptions

If you need to modify the blocked words list:

1. Update `.githooks/commit-msg` (local enforcement)
2. Update `.github/workflows/commit-message-check.yml` (server enforcement)
3. Update this documentation
4. Communicate changes to all contributors

## Troubleshooting

### "Cannot push to GitHub"

If your push is rejected:

1. Check the GitHub Actions tab for details
2. Look for the "Commit Message Check" workflow
3. Review which commits failed the check
4. Use `git rebase -i` to fix the messages

### Emergency Override

In true emergencies where you cannot modify history:

1. Create a new branch
2. Cherry-pick the good commits
3. Create new commits with proper messages
4. Submit PR from the clean branch

## Best Practices

1. **Write good messages first time**: Saves time vs. fixing later
2. **Use commitizen**: `npm install -g commitizen` for interactive commits
3. **Configure your editor**: Set up commit message templates
4. **Review before pushing**: `git log --oneline` to check messages

## Integration with CI/CD

The commit message check integrates with our broader CI/CD pipeline:

- Runs in parallel with security scans
- Fast feedback (usually < 30 seconds)
- Clear error messages with fix instructions
- Required for all protected branches

Remember: These rules apply to everyone, including administrators, ensuring a consistent and professional repository for all contributors.
