# Git Tasks

This module provides GitHub integration tasks for managing branches, workflow runs, security vulnerabilities, and pull request comments.

## Available Tasks

```bash
task git:                # Show available Git tasks
task git:prune           # Delete local branches without remotes
task git:fetch-prune     # Fetch and prune remote branches
task git:switch-default  # Switch to default branch
task git:list-branches   # List all branches with status
task git:delete-runs     # Delete GitHub workflow runs
task git:cve:analyze     # Analyze security vulnerabilities
task git:cve:list        # List Dependabot alerts
task git:pr:comments     # Download PR comments (including GHAS)
```

## Task Details

### Pull Request Comments (`task git:pr:comments`)

Downloads all comments from a pull request including:
- General PR comments
- Code review comments (inline)
- Review approvals/rejections
- GitHub Advanced Security (GHAS) alerts
- CodeQL findings
- Security check runs

**Usage:**

```bash
# Interactive mode - select from list
task git:pr:comments

# Download specific PR
task git:pr:comments PR=123

# Download latest PR
task git:pr:comments PR=latest

# Custom output directory
task git:pr:comments PR=21 OUTPUT=./reports/pr-comments
```

**Output Files:**
- `pr-{number}-metadata.json` - PR details
- `pr-{number}-issue-comments.json` - General comments
- `pr-{number}-review-comments.json` - Code review comments
- `pr-{number}-reviews.json` - Review decisions
- `pr-{number}-check-runs.json` - CI/Security checks
- `pr-{number}-report.md` - Consolidated markdown report

**Features:**
- Extracts GHAS/CodeQL security findings
- Organized markdown report with all comments
- Automatic report opening in VS Code
- Support for pagination (all comments downloaded)

### Branch Management

#### Delete Local Branches (`task git:prune`)

Removes local branches that no longer exist on remote:

```bash
# Clean current repository
task git:prune

# Clean all repositories in a directory
task git:prune BASE_DIR=~/projects

# Aliases
task git:clean-branches
task git:clb
```

#### Fetch and Prune (`task git:fetch-prune`)

Updates remote references and removes stale branches:

```bash
task git:fetch-prune
task git:fp  # alias
```

#### Switch to Default Branch (`task git:switch-default`)

Automatically switches to main/master branch:

```bash
task git:switch-default
task git:sd  # alias
```

### GitHub Workflow Management

#### Delete Workflow Runs (`task git:delete-runs`)

Remove workflow runs by status:

```bash
# Delete failed runs from current branch
task git:delete-runs

# Delete from specific branch
task git:delete-runs BRANCH=feature/new-feature STATUS=failure

# Delete all cancelled runs
task git:delete-runs BRANCH=all STATUS=cancelled

# Valid statuses
# queued, completed, in_progress, requested, waiting, 
# action_required, cancelled, failure, neutral, skipped, 
# stale, startup_failure, success, timed_out
```

### Security Analysis

#### Analyze Vulnerabilities (`task git:cve:analyze`)

Comprehensive vulnerability scanning using GitHub Dependabot:

```bash
# Scan for medium+ severity
task git:cve:analyze

# Include low severity
task git:cve:analyze MIN_SEVERITY=low

# Only critical issues
task git:cve:analyze MIN_SEVERITY=critical
```

**Output:**
- Summary report with CVE details
- Filtered JSON data
- Raw API response
- Saved to `./logs/vulnerabilities/`

#### List Dependabot Alerts (`task git:cve:list`)

Quick overview of all security alerts:

```bash
task git:cve:list
task git:vl  # alias
```

## Configuration

### Authentication

All GitHub-related tasks require authentication. The tasks will automatically check for authentication in this order:

1. **`.env` file** - If present, loads `GITHUB_TOKEN` from the file
2. **GitHub CLI** - If authenticated with `gh`, uses its token
3. **Error with instructions** - If neither is available, shows detailed setup instructions

#### Setting up authentication:

**Option 1: Using .env file (simple)**:
```bash
# Create a GitHub personal access token at:
# https://github.com/settings/tokens/new
# Required scopes: repo, read:org (for private repos)

# Add to .env file
echo 'GITHUB_TOKEN=ghp_your_token_here' >> .env
```

**Option 2: Using GitHub CLI (recommended)**:
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

The tasks will automatically load the `.env` file if present, or use the GitHub CLI token if authenticated. If neither is available, you'll see a helpful error message with setup instructions.

### Requirements

- **git** - Version control
- **gh** - GitHub CLI (recommended)
- **jq** - JSON processing
- **curl** - API calls (fallback)

Install GitHub CLI:
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

## Examples

### Complete PR Review Workflow

```bash
# 1. Download PR comments and security findings
task git:pr:comments PR=21

# 2. Review GHAS alerts in the report
cat .github/pr-comments/pr-21-report.md

# 3. Check specific security findings
jq '.[] | select(.app.slug == "github-code-scanning")' \
  .github/pr-comments/pr-21-check-runs.json
```

### Security Audit Workflow

```bash
# 1. Check current vulnerabilities
task git:cve:analyze MIN_SEVERITY=low

# 2. List all Dependabot alerts
task git:cve:list

# 3. Review detailed report
cat ./logs/vulnerabilities/vulns-*-summary.txt
```

### Branch Cleanup Workflow

```bash
# 1. Fetch latest from remote
task git:fetch-prune

# 2. Switch to main branch
task git:switch-default

# 3. Delete stale local branches
task git:prune
```

## Tips and Tricks

### Filtering PR Comments

Extract specific types of comments:

```bash
# Get only security-related comments
jq '.[] | select(.body | contains("security"))' \
  .github/pr-comments/pr-21-issue-comments.json

# Find unresolved review comments
jq '.[] | select(.resolved == false)' \
  .github/pr-comments/pr-21-review-comments.json
```

### Automating Reports

Create a script to download all PR comments:

```bash
#!/bin/bash
for pr in $(gh pr list --limit 10 --json number --jq '.[].number'); do
  task git:pr:comments PR=$pr OUTPUT=./reports/pr-$pr
done
```

### CI Integration

Use in GitHub Actions:

```yaml
- name: Download PR Comments
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    task git:pr:comments PR=${{ github.event.pull_request.number }}
    
- name: Upload PR Report
  uses: actions/upload-artifact@v3
  with:
    name: pr-comments
    path: .github/pr-comments/
```

## Troubleshooting

### Authentication Issues

If you get authentication errors:

1. Check gh CLI status:
   ```bash
   gh auth status
   ```

2. Verify token in .env:
   ```bash
   cat .env | grep GITHUB_TOKEN
   ```

3. Test API access:
   ```bash
   gh api user
   ```

### Rate Limiting

GitHub API has rate limits. If hit:

1. Wait for reset (usually 1 hour)
2. Use authenticated requests (higher limits)
3. Cache results locally

### Missing Comments

If some comments are missing:

1. Check pagination is working (should see "paginate" in commands)
2. Verify PR number is correct
3. Check permissions on private repos

## Best Practices

1. **Use gh CLI** - Better authentication and pagination support
2. **Cache results** - Save API calls by storing outputs
3. **Filter at source** - Use API parameters to reduce data transfer
4. **Regular cleanup** - Run branch pruning weekly
5. **Security first** - Review GHAS alerts before merging

## Resources

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [GitHub Advanced Security](https://docs.github.com/en/code-security/code-scanning)