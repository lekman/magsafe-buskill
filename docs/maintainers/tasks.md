# Maintainer Tasks Documentation

This document describes the various maintenance tasks available in the project's Taskfile, including security operations, testing, and development workflows.

## Security Tasks

### Pin GitHub Actions (`task security:pin-actions`)

**Purpose**: Pins all GitHub Actions to specific commit SHAs for supply chain security.

**How it works**:

1. Scans all workflow files in `.github/workflows/`
2. For each action reference (e.g., `actions/checkout@v3`), fetches the corresponding commit SHA
3. Replaces version tags with SHAs, preserving the version as a comment
4. Supports GitHub authentication via `GITHUB_TOKEN` environment variable

**Example transformation**:

```yaml
# Before
uses: actions/checkout@v3

# After
uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608 # v3
```

**Requirements**:

- `jq` installed (`brew install jq`)
- Optional: `GITHUB_TOKEN` in `.env` file for higher API rate limits

**Usage**:

```bash
# Pin all actions
task security:pin-actions

# With GitHub token for better rate limits
echo "GITHUB_TOKEN=your_token_here" > .env
task security:pin-actions
```

### Update Action Pins (`task security:update-pins`)

**Purpose**: Updates pinned GitHub Actions to their latest SHAs while maintaining the same version tags.

**How it works**:

1. Finds all pinned actions (those with SHA and version comment)
2. Checks if newer SHAs are available for the same version
3. Updates only those that have newer commits
4. Preserves version comments for traceability

**Usage**:

```bash
# Check and update all pinned actions
task security:update-pins
```

### Check Pin Status (`task security:check-pins`)

**Purpose**: Verifies all GitHub Actions are properly pinned to SHAs.

**How it works**:

1. Scans workflow files for unpinned actions
2. Reports any actions using version tags instead of SHAs
3. Exits with error if unpinned actions are found

**Usage**:

```bash
# Check pin status
task security:check-pins
```

### Scan for Secrets (`task security:scan-secrets`)

**Purpose**: Scans codebase for potential secrets and sensitive data.

**Patterns checked**:

- Passwords in code
- API keys
- Secret tokens
- Private keys
- Bearer tokens

**Usage**:

```bash
# Scan for secrets
task security:scan-secrets
```

### Setup Dependabot (`task security:dependabot`)

**Purpose**: Creates Dependabot configuration for automated dependency updates.

**Features**:

- Weekly checks for GitHub Actions updates
- Weekly checks for Swift package updates
- Groups all action updates into single PRs
- Automatic labeling and commit message formatting

**Usage**:

```bash
# Setup Dependabot
task security:dependabot
```

## Testing Tasks

### Run All Tests (`task test`)

Runs security checks and Swift tests in sequence.

### Test with Coverage (`task test:coverage`)

**Purpose**: Runs tests with code coverage and enforces 80% minimum.

**Features**:

- Generates detailed coverage report
- Excludes test files, mocks, and UI code from coverage
- Fails if coverage is below 80%
- Shows which files need more tests

**Excluded patterns**:

- `*Tests.swift`
- `Mock*.swift`
- `MagSafeGuardApp.swift`
- `PowerMonitorService.swift`
- `*LAContext.swift`
- `MacSystemActions.swift`
- `*Protocol.swift`

### Generate HTML Coverage (`task test:coverage:html`)

Generates an HTML coverage report and opens it in the browser.

### Security Tests (`task test:security`)

Runs basic security checks:

- Hardcoded password detection
- Private key file detection
- Semgrep scan (if installed)

## Development Tasks

### Initialize Environment (`task init`)

Sets up the complete development environment:

1. Checks required tools
2. Configures git hooks
3. Sets up SBOM generation
4. Verifies setup

### Run Application (`task run`)

Builds and runs MagSafe Guard as a menu bar application:

- Builds in release mode
- Creates temporary app bundle
- Launches the application

### Run in Debug Mode (`task run:debug`)

Similar to `run` but builds in debug mode for development.

### Linting (`task lint`)

Runs all linters:

- SwiftLint for Swift code
- markdownlint for Markdown files

### Fix Linting Issues (`task lint:fix`)

Automatically fixes linting issues where possible.

### Generate SBOM (`task sbom`)

Generates Software Bill of Materials in SPDX format:

- Creates `sbom.spdx` file
- Lists all dependencies
- Includes version and license information

## Pre-Push Workflow

### Pre-Push Checks (`task pre-push`)

Runs all checks before pushing:

1. Fixes Markdown formatting
2. Runs tests with coverage
3. Runs security scans
4. Runs linters
5. Generates SBOM
6. Updates documentation

### Pre-PR Checks (`task pre-pr`)

Similar to pre-push but optimized for pull request creation.

## Git Hooks

The project uses git hooks for automated checks:

### Pre-commit Hook

- Checks for hardcoded secrets
- Detects private key files
- Prevents committing .env files
- Runs Semgrep scan (if installed)

### Commit-msg Hook

- Validates conventional commit format
- Blocks certain words in commit messages

## Best Practices

### Security

1. **Always pin actions**: Run `task security:pin-actions` after adding new workflows
2. **Regular updates**: Use `task security:update-pins` to get security fixes
3. **Enable Dependabot**: Run `task security:dependabot` for automated updates

### Testing

1. **Maintain coverage**: Keep code coverage above 80%
2. **Exclude appropriately**: UI and system integration code should be excluded
3. **Run before push**: Always run `task pre-push` before pushing changes

### Development

1. **Use conventional commits**: `task commit` helps format correctly
2. **Fix linting issues**: Run `task lint:fix` before committing
3. **Keep SBOM updated**: Generate after dependency changes

## Troubleshooting

### GitHub API Rate Limits

If you encounter rate limit errors:

1. Create a GitHub personal access token
2. Add to `.env`: `GITHUB_TOKEN=your_token_here`
3. Source the file: `source .env`

### Missing Tools

Install required tools:

```bash
# macOS with Homebrew
brew install jq swiftlint markdownlint-cli semgrep
```

### Test Failures

If tests fail with signal 6:

- Check for UNUserNotificationCenter usage in tests
- Ensure NotificationService.disableForTesting is set
- Use mock delivery methods in tests

## Maintenance Schedule

### Weekly

- Run `task security:update-pins` to check for action updates
- Review Dependabot PRs for dependency updates

### Before Each Release

- Run `task pre-push` for comprehensive checks
- Update SBOM with `task sbom`
- Verify security with `task security`

### After Adding Dependencies

- Regenerate SBOM
- Update coverage exclusions if needed
- Run full test suite
