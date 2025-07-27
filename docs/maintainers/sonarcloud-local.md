# Running SonarCloud Analysis Locally

This guide explains how to run SonarCloud analysis locally for debugging and pre-commit validation.

## Prerequisites

1. **Install sonar-scanner** (for full analysis):

   ```bash
   # macOS
   brew install sonar-scanner

   # Linux/Windows
   # Download from https://docs.sonarcloud.io/advanced-setup/ci-based-analysis/sonarscanner-cli/
   ```

2. **Install jq** (optional, for parsing results):

   ```bash
   brew install jq
   ```

## Available Tasks

### 1. Run Full SonarCloud Analysis

```bash
# Add token to .env file
echo 'SONAR_TOKEN=your-token-here' >> .env

# Run analysis with upload to SonarCloud
task sonar
```

### 2. Simulate Analysis (No Scanner Required)

```bash
# Run local analysis using SwiftLint
task sonar:simulate

# View the simulation report
task sonar:view
```

### 3. Download Findings from SonarCloud

```bash
# Download all current findings from SonarCloud
task sonar:download

# View downloaded findings
cat .sonarcloud/sonarcloud-findings.txt | less
```

## Setting Up Your Token

1. Get your token from: https://sonarcloud.io/account/security
2. Add it to your `.env` file:

   ```bash
   echo 'SONAR_TOKEN=your-sonarcloud-token' >> .env
   ```

The tasks will automatically load the token from `.env`.

## Understanding Results

### Local Files Generated

After running `task sonar`, you'll find:

- `.sonarcloud/sonar-scanner.log` - Full analysis log
- `.sonarcloud/sonar-report.json` - Issues report (preview mode only)
- `coverage.xml` - Coverage data used by SonarCloud

### Common Issues to Look For

1. **Code Smells** - Maintainability issues
2. **Bugs** - Reliability issues  
3. **Vulnerabilities** - Security issues
4. **Security Hotspots** - Code that needs security review
5. **Coverage** - Lines/branches not covered by tests

### Interpreting the Log

The scanner log shows:

```text
INFO: CPD Executor # lines for duplication detection
INFO: Load project repositories
INFO: # issues found on # files
INFO: Quality profile for swift: # active rules
```

## Configuration

The analysis uses `sonar-project.properties` for configuration:

- **sonar.sources** - Source directories to analyze
- **sonar.tests** - Test directories
- **sonar.exclusions** - Files to exclude from analysis
- **sonar.coverage.exclusions** - Files to exclude from coverage

## Troubleshooting

### No Coverage Data

If you see "No coverage.xml found", the coverage generation may have failed:

```bash
# Generate coverage manually
task test:coverage

# Then run sonar again
task sonar
```

### Authentication Issues

If you see authentication errors:

1. Check your SONAR_TOKEN is valid
2. Ensure you have access to the project on SonarCloud
3. Try regenerating your token

### Parse Errors

If Swift files fail to parse:

1. Ensure code compiles successfully first
2. Check for unsupported Swift syntax
3. Review the exclusions in sonar-project.properties

## Integration with Development Workflow

### Pre-Push Check

Add SonarCloud check to your pre-push workflow:

```bash
# In your pre-push hook or task
task sonar || echo "SonarCloud issues found - review before pushing"
```

### CI/CD Integration

The same analysis runs in GitHub Actions. Local analysis helps catch issues before they reach CI.

## Tips

1. **Focus on New Code** - Don't try to fix all legacy issues at once
2. **Set Quality Gates** - Define what issues block merging
3. **Regular Scans** - Run locally before significant commits
4. **Review Security Hotspots** - These need human review, not just fixes

## Resources

- [SonarCloud Documentation](https://docs.sonarcloud.io/)
- [Swift Analysis Rules](https://rules.sonarsource.com/swift)
- [Understanding Quality Gates](https://docs.sonarcloud.io/improving/quality-gates/)
