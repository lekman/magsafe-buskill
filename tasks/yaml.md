# YAML Tasks

This module provides YAML validation and linting for all YAML files in the project, including GitHub Actions workflows, task files, and configuration files.

## Available Tasks

```bash
task yaml:         # Show available YAML tasks
task yaml:lint     # Lint YAML files with yamllint
task yaml:lint:fix # Auto-fix YAML formatting issues
task yaml:validate # Basic syntax validation
task yaml:setup    # Install yamllint and create config
task yaml:ci       # Run linting with CI-friendly output
task yaml:report   # Generate JSON linting report
```

## Task Details

### Lint YAML Files (`task yaml:lint`)

Comprehensive YAML linting with style rules:

- Validates syntax and structure
- Checks formatting consistency
- Enforces style guidelines
- Reports all issues

**Default patterns:**

- `*.yml`, `*.yaml` (root directory)
- `.github/**/*.yml` (GitHub workflows)
- `tasks/*.yml` (task files)

**Custom patterns:**

```bash
# Lint specific files
FILES="config.yml,docker-compose.yml" task yaml:lint

# Lint multiple patterns
FILES=".github/**/*.yml,k8s/*.yaml" task yaml:lint
```

### Auto-fix Formatting (`task yaml:lint:fix`)

Automatically fixes formatting issues:

- Consistent indentation
- Proper line spacing
- Quote normalization
- Bracket alignment

**Formatters supported:**

1. **prettier** (recommended) - Best formatting
2. **yq** - Basic formatting

**Usage:**

```bash
# Fix all YAML files
task yaml:lint:fix

# Fix specific files
FILES="broken.yml" task yaml:lint:fix
```

### Validate Syntax (`task yaml:validate`)

Quick syntax validation without style rules:

- Checks YAML parsability
- Reports syntax errors
- No style enforcement
- Fast validation

**Usage:**

```bash
# Validate all files
task yaml:validate

# Validate specific pattern
FILES=".github/workflows/*.yml" task yaml:validate
```

### Setup Tools (`task yaml:setup`)

Installs yamllint and creates default config:

- Installs yamllint via brew or pip
- Creates `.yamllint.yml` config
- Suggests additional tools
- Ready for immediate use

### CI Mode (`task yaml:ci`)

Optimized for CI/CD pipelines:

- GitHub Actions annotations
- Machine-readable output
- Exit codes for CI
- Parseable format

**GitHub Actions example:**

```yaml
- name: Lint YAML files
  run: task yaml:ci
```

### Generate Report (`task yaml:report`)

Creates JSON report of all issues:

- Machine-readable format
- Detailed issue information
- Line and column numbers
- Severity levels

**Usage:**

```bash
# Default report
task yaml:report

# Custom output file
OUTPUT=report.json task yaml:report

# Specific files
FILES="*.yml" OUTPUT=yaml-issues.json task yaml:report
```

## Configuration

### Default Config (.yamllint.yml)

Created by `task yaml:setup`:

```yaml
---
extends: default

rules:
  line-length:
    max: 120
    level: warning
  
  # Allow multiple spaces for alignment
  colons:
    max-spaces-after: -1
  
  # Optional document start
  document-start: disable
  
  # Flexible quoting
  quoted-strings:
    quote-type: any
    required: false
  
  # Consistent indentation
  indentation:
    spaces: consistent
    indent-sequences: true
  
  # Allow common boolean values
  truthy:
    allowed-values: ['true', 'false', 'on', 'off', 'yes', 'no']

# Ignore patterns
ignore: |
  .git/
  node_modules/
  vendor/
  .build/
  *.min.yml
```

### Custom Rules

Modify `.yamllint.yml` for project needs:

```yaml
# Strict mode
extends: default
rules:
  line-length:
    max: 80
  document-start: enable
  comments:
    min-spaces-from-content: 2

# Relaxed mode
rules:
  line-length: disable
  indentation:
    spaces: 2
  truthy: disable
```

## Integration with QA

### Add to Standard QA

Update main Taskfile.yml:

```yaml
qa:
  desc: Run standard quality checks
  cmds:
    - task: yaml:lint
    - task: swift:lint
    - task: markdown:lint
```

### Pre-commit Hook

Add to `.githooks/pre-commit`:

```bash
# Check YAML files
if git diff --cached --name-only | grep -E '\.(yml|yaml)$' > /dev/null; then
  echo "Checking YAML files..."
  FILES=$(git diff --cached --name-only | grep -E '\.(yml|yaml)$' | tr '\n' ',')
  FILES="$FILES" task yaml:lint || exit 1
fi
```

### GitHub Actions

Add to workflow:

```yaml
- name: Setup tools
  run: |
    task yaml:setup
    task swift:setup

- name: Lint all files
  run: |
    task yaml:ci
    task swift:lint
```

## Common Issues

### Pattern Matching

For recursive patterns:

```bash
# ✓ Correct - quotes preserve wildcards
FILES=".github/**/*.yml" task yaml:lint

# ✗ Wrong - shell expands before task runs
FILES=.github/**/*.yml task yaml:lint
```

### File Not Found

If files aren't found:

1. Check pattern syntax
2. Verify file extensions (.yml vs .yaml)
3. Use `find` to test pattern:

   ```bash
   find .github -name "*.yml" -type f
   ```

### Permission Errors

For system files:

```bash
# Run with elevated permissions if needed
sudo task yaml:lint FILES="/etc/docker/daemon.json"
```

## Tips and Tricks

### Quick Validation

For rapid feedback during editing:

```bash
# Watch mode with entr
ls *.yml | entr task yaml:validate
```

### Selective Linting

Lint only changed files:

```bash
# In git repository
FILES=$(git diff --name-only | grep -E '\.(yml|yaml)$' | tr '\n' ',')
[ -n "$FILES" ] && FILES="$FILES" task yaml:lint
```

### Custom Severity

Override rule severity in `.yamllint.yml`:

```yaml
rules:
  line-length:
    max: 120
    level: warning  # or error
```

### IDE Integration

**VS Code:**

1. Install "YAML" extension
2. Add to settings.json:

   ```json
   "yaml.customTags": [
     "!reference sequence"
   ],
   "yaml.validate": true
   ```

**Vim:**

```vim
" Auto-lint on save
autocmd BufWritePost *.yml,*.yaml !task yaml:lint FILES=%
```

## Best Practices

1. **Run setup first**: `task yaml:setup`
2. **Lint before commit**: Add to pre-commit hooks
3. **Fix automatically**: Use `yaml:lint:fix` when possible
4. **Validate in CI**: Use `yaml:ci` for pipelines
5. **Document exceptions**: Add comments for disabled rules

## Troubleshooting

### Installation Issues

If yamllint won't install:

```bash
# macOS
brew update && brew install yamllint

# Linux/Universal
pip3 install --user yamllint

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

### Config Not Found

If `.yamllint.yml` is ignored:

```bash
# Specify explicitly
yamllint -c .yamllint.yml file.yml

# Or set environment variable
export YAMLLINT_CONFIG_FILE=.yamllint.yml
```

### Performance

For large projects:

```bash
# Parallel processing
find . -name "*.yml" -print0 | xargs -0 -P 4 -n 1 yamllint
```

## Resources

- [yamllint Documentation](https://yamllint.readthedocs.io/)
- [YAML Specification](https://yaml.org/spec/)
- [GitHub Actions YAML](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Prettier YAML](https://prettier.io/docs/en/options.html#yaml)
