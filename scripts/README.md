# Security Scripts

This directory contains automated security scripts for maintaining GitHub Actions and repository security.

## Scripts

### pin-github-actions.sh

Automatically pins all GitHub Actions in workflow files to their specific commit SHAs for supply chain security.

**Features:**
- Automatically fetches the latest SHA for each action version
- Preserves version comments for readability
- Handles both version tags (e.g., `v4`) and branch names (e.g., `main`)
- Provides detailed progress and error reporting
- Creates backups before modifying files

**Usage:**
```bash
./scripts/pin-github-actions.sh
# or via Task:
task security:pin-actions
```

### update-action-pins.sh

Updates existing pinned GitHub Actions to their latest SHAs while maintaining the same version tags.

**Features:**
- Only updates SHAs for already-pinned actions
- Preserves the version tag specified in comments
- Shows which actions were updated
- Provides a summary of changes

**Usage:**
```bash
./scripts/update-action-pins.sh
# or via Task:
task security:update-pins
```

## Task Commands

The Taskfile.yml includes several security-related tasks:

- `task security` - Run all security checks
- `task security:fix` - Apply all security fixes automatically
- `task security:pin-actions` - Pin all GitHub Actions to SHAs
- `task security:update-pins` - Update existing pins to latest SHAs
- `task security:check-pins` - Verify all actions are pinned
- `task security:scan-secrets` - Scan for secrets and sensitive data
- `task security:dependabot` - Set up Dependabot configuration

## Requirements

- **jq** - Required for parsing GitHub API responses
  - Install with: `brew install jq`
- **curl** - For making GitHub API requests (pre-installed on macOS)
- **bash** - Version 4.0 or higher

## Security Benefits

1. **Supply Chain Security**: Pinning actions to SHAs prevents supply chain attacks where an action's tag could be moved to malicious code
2. **Reproducibility**: Ensures workflows always use the exact same action code
3. **Audit Trail**: Comments preserve the version tag for easy reference
4. **Automation**: Scripts eliminate manual work and reduce human error

## Best Practices

1. Run `task security:pin-actions` after adding new actions to workflows
2. Use `task security:update-pins` periodically to get security updates
3. Review changes with `git diff` before committing
4. Set up Dependabot to automate updates with `task security:dependabot`
5. Include security checks in your CI/CD pipeline

## Troubleshooting

### Rate Limiting
If you encounter GitHub API rate limits:
- Wait 60 minutes for the rate limit to reset
- Use a GitHub token by setting `GITHUB_TOKEN` environment variable
- Run the script during off-peak hours

### Action Not Found
If an action can't be found:
- Verify the action name and version are correct
- Check if the repository is public
- Ensure the version tag exists

### Permission Errors
If you get permission errors:
- Ensure scripts are executable: `chmod +x scripts/*.sh`
- Check file permissions on workflow files
- Verify you have write access to the repository