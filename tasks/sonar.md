# SonarCloud Tasks

This module provides code quality analysis and SonarCloud integration for comprehensive code review.

## Available Tasks

```bash
task sonar:            # Show available SonarCloud tasks
task sonar:scan        # Run full SonarCloud analysis
task sonar:download    # Download findings from SonarCloud
task sonar:download:pr # Download pull request report
task sonar:convert     # Convert Swift coverage to SonarQube XML
task sonar:setup       # Install sonar-scanner
task sonar:issues      # Display findings from previous scan
```

## Task Details

### Full Analysis (`task sonar:scan`)

Runs complete SonarCloud analysis with upload:

- Generates test coverage data
- Analyzes code quality metrics
- Uploads results to SonarCloud
- Reports quality gate status

**Requirements:**

- SonarCloud token in `.env` file
- sonar-scanner installed

### Local Analysis Alternative

For quick local analysis without SonarCloud:

- Use `task swift:lint` for SwiftLint analysis
- Use `task swift:test:coverage` for coverage reports
- No token required
- Immediate feedback

### Download Findings (`task sonar:download`)

Fetches all current issues from SonarCloud:

- Downloads via SonarCloud API
- Creates readable report
- Shows issue summary
- Tracks quality trends

**Output:**

- `.sonarcloud/sonarcloud-issues.json`
- `.sonarcloud/sonarcloud-findings.txt`

### Download PR Report (`task sonar:download:pr`)

Downloads pull request analysis from SonarCloud:

- Interactive PR selection
- Quality metrics for PR
- Issue details with severity
- Markdown report generation

**Usage:**

```bash
# Interactive mode (choose from list)
task sonar:download:pr

# Download specific PR by number
PR=123 task sonar:download:pr

# Download latest PR without interaction
PR=latest task sonar:download:pr

# Show usage help
PR=help task sonar:download:pr
```

**Output:**

- `.sonarcloud/pr-{number}-report.md`
- `.sonarcloud/pr-{number}-issues.json`
- `.sonarcloud/pr-{number}-measures.json`

### Display Issues (`task sonar:issues`)

Shows SonarCloud findings from previous scan:

- Summary of open/closed issues
- Breakdown by severity
- Opens full report in VSCode
- No network access required

### Convert Coverage (`task sonar:convert`)

Converts Swift coverage to SonarQube format:

- Transforms llvm-cov output
- Creates `coverage.xml`
- Compatible with SonarCloud
- Excludes test files

### Install Scanner (`task sonar:setup`)

Installs sonar-scanner tool:

- Detects OS automatically
- macOS: Uses Homebrew
- Linux: Downloads binary
- Configures PATH

## Configuration

### SonarCloud Token

1. Get token from [SonarCloud Security](https://sonarcloud.io/account/security)
2. Add to `.env` file:

   ```bash
   echo 'SONAR_TOKEN=your-token-here' >> .env
   ```

### Project Settings

Configure in `sonar-project.properties`:

```properties
# Project identification
sonar.projectKey=lekman_magsafe-buskill
sonar.organization=lekman

# Source configuration
sonar.sources=Sources
sonar.tests=Tests

# Exclusions
sonar.exclusions=**/*.md,**/.*,**/*.yml
sonar.coverage.exclusions=**/*Tests.swift,**/Mock*.swift
```

### Coverage Configuration

Exclusion patterns:

- Test files: `*Tests.swift`
- Mock objects: `Mock*.swift`
- UI entry point: `MagSafeGuardApp.swift`
- System integrations: `MacSystemActions.swift`
- Protocols: `*Protocol.swift`

## Quality Metrics

### Issue Types

1. **Bugs** - Code reliability issues
2. **Vulnerabilities** - Security problems
3. **Code Smells** - Maintainability issues
4. **Security Hotspots** - Needs security review
5. **Duplications** - Copy-pasted code

### Quality Gates

Default thresholds:

- Coverage: 80% minimum
- Duplications: 3% maximum
- Maintainability: A rating
- Reliability: A rating
- Security: A rating

## Integration Workflow

### Local Development

```bash
# Before committing (quick check)
task swift:lint
task swift:test:coverage

# Before pushing (with token)
task sonar:scan
```

### CI/CD Pipeline

Automated in GitHub Actions:

- Pull requests: Comments with issues
- Main branch: Full analysis
- Quality gate enforcement

### Pre-push Validation

Add to pre-push workflow:

```bash
# Quick local check
task swift:lint

# Full check (requires token)
task qa:full
```

## Troubleshooting

### No Coverage Data

If coverage is missing:

```bash
# Generate coverage first
task swift:test:coverage

# Then run analysis
task sonar:scan
```

### Authentication Failed

Token issues:

1. Verify token in `.env`
2. Check token permissions
3. Ensure project access
4. Regenerate if needed

### Scanner Not Found

Install sonar-scanner:

```bash
# Using task
task sonar:setup

# Or manually on macOS
brew install sonar-scanner
```

### Parse Errors

Swift parsing issues:

1. Ensure code compiles
2. Check Swift version
3. Review exclusions
4. Update scanner

### Rate Limiting

API rate limit errors:

1. Wait before retrying
2. Use authentication token
3. Reduce API calls
4. Cache results

## Best Practices

### Code Quality

1. **Fix new issues first** - Don't let debt accumulate
2. **Set realistic goals** - Gradual improvement
3. **Review security hotspots** - Manual verification needed
4. **Track trends** - Monitor quality over time
5. **Automate checks** - Integrate in CI/CD

### Coverage Strategy

1. **Focus on critical paths** - Business logic first
2. **Exclude UI code** - Hard to test effectively
3. **Test edge cases** - Improve reliability
4. **Monitor trends** - Don't let coverage drop
5. **Set team goals** - Agree on thresholds

### Issue Resolution

1. **Prioritize by severity** - Critical first
2. **Fix root causes** - Not just symptoms
3. **Document exceptions** - When issues can't be fixed
4. **Learn from patterns** - Prevent future issues
5. **Celebrate improvements** - Recognize progress

## Advanced Usage

### Custom Rules

Add custom rules in `.sonarcloud/rules/`:

```yaml
rules:
  - key: custom-rule-1
    name: Custom Security Check
    severity: MAJOR
    type: VULNERABILITY
```

### Baseline Exclusions

For legacy code:

```properties
# Exclude legacy code from new issues
sonar.exclusions=Legacy/**/*
sonar.issue.ignore.multicriteria=e1
sonar.issue.ignore.multicriteria.e1.ruleKey=*
sonar.issue.ignore.multicriteria.e1.resourceKey=Legacy/**/*
```

### Branch Analysis

Configure branch analysis:

```bash
# Analyze feature branch
sonar-scanner \
  -Dsonar.branch.name=feature/new-feature \
  -Dsonar.branch.target=main
```

## Tips and Tricks

### Performance

- Use `task swift:lint` for quick feedback
- Cache scanner downloads
- Exclude generated files
- Run coverage separately

### Accuracy

- Keep exclusions minimal
- Update scanner regularly
- Review false positives
- Configure rules appropriately

### Team Adoption

- Start with local linting
- Gradually enable rules
- Share success stories
- Make it part of workflow

## Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [Swift Analysis Rules](https://rules.sonarsource.com/swift)
- [Quality Gates Guide](https://docs.sonarcloud.io/improving/quality-gates/)
- [Coverage Best Practices](https://docs.sonarcloud.io/enriching/test-coverage/)
