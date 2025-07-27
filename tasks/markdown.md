# Markdown Tasks

This module provides markdown linting and formatting capabilities to ensure consistent documentation.

## Available Tasks

```bash
task markdown:         # Show available markdown tasks
task markdown:lint     # Lint all markdown files
task markdown:fix      # Auto-fix markdown issues
task markdown:pr       # Check PR description formatting
task markdown:pr:fix   # Fix PR description formatting
```

## Task Details

### Linting (`task markdown:lint`)

Checks all markdown files for style and formatting issues:

- Line length violations
- Missing blank lines
- Incorrect heading levels
- Trailing spaces
- Inconsistent formatting

**Files checked:**

- All `*.md` files in the project
- Excludes `.build/` and `node_modules/`

### Auto-fix (`task markdown:fix`)

Automatically fixes common markdown issues:

- Adds missing blank lines
- Fixes heading formatting
- Removes trailing spaces
- Standardizes list markers
- Fixes table formatting

**Safe operations only** - manual review recommended.

### PR Description Check (`task markdown:pr`)

Validates pull request descriptions:

- Checks for required sections
- Validates checkbox formatting
- Ensures proper structure

**Required sections:**

- Description
- Type of change
- Testing checklist

### PR Description Fix (`task markdown:pr:fix`)

Fixes common PR description issues:

- Corrects checkbox syntax
- Adds missing sections
- Formats headers properly

## Configuration

### markdownlint Rules

Configure in `.markdownlint.yaml`:

```yaml
# Disable specific rules
MD013: false # Line length
MD033: false # Inline HTML

# Configure rules
MD007:
  indent: 2 # Unordered list indentation

# Ignore files
MD041:
  exclude:
    - CHANGELOG.md
```

### Custom Rules

Add project-specific rules:

```yaml
# Require blank lines around headings
MD022: true
MD023: true
MD024: true

# List formatting
MD004:
  style: dash # Use - for lists
```

## Common Issues and Fixes

### Line Too Long (MD013)

**Issue:** Lines exceed maximum length

```markdown
This is a very long line that exceeds the maximum configured line length and will cause a linting error.
```

**Fix:** Break into multiple lines

```markdown
This is a very long line that exceeds the maximum
configured line length and will cause a linting error.
```

### Missing Blank Lines (MD022, MD031)

**Issue:** No blank lines around headings/code blocks

````markdown
## Heading

Some text

```code

```
````

**Fix:** Add blank lines

````markdown
## Heading

Some text

```code

```
````

### Trailing Spaces (MD009)

**Issue:** Spaces at end of lines

```markdown
Some text with trailing spaces
```

**Fix:** Remove trailing spaces or use proper line breaks

```markdown
Some text with trailing spaces
```

### Inconsistent List Markers (MD004)

**Issue:** Mixed list markers

```markdown
- Item 1

* Item 2

- Item 3
```

**Fix:** Use consistent markers

```markdown
- Item 1
- Item 2
- Item 3
```

## Integration with Development Workflow

### Pre-commit Hook

Markdown linting runs automatically on commit:

- Checks modified `.md` files
- Prevents commit if errors found
- Suggests running `task markdown:fix`

### CI/CD Pipeline

Pull requests automatically:

- Run `task markdown:lint`
- Comment on PR with issues
- Block merge if errors exist

### Editor Integration

#### VS Code

Install the markdownlint extension:

```bash
code --install-extension DavidAnson.vscode-markdownlint
```

#### Vim

Add to `.vimrc`:

```vim
let g:ale_linters = {'markdown': ['markdownlint']}
```

## Best Practices

### Documentation Standards

1. **Use consistent heading levels** - Don't skip levels
2. **Add blank lines** around headings and code blocks
3. **Use code fences** with language specifiers
4. **Keep lines under 80 characters** when possible
5. **Use reference-style links** for repeated URLs

### File Organization

```ini
docs/
├── README.md          # Project overview
├── CONTRIBUTING.md    # Contribution guidelines
├── CHANGELOG.md       # Version history
├── api/               # API documentation
├── guides/            # User guides
└── development/       # Developer docs
```

### Writing Tips

#### Clear Structure

```markdown
# Main Topic

Brief introduction paragraph.

## Subtopic 1

Detailed explanation with examples.

### Specific Feature

- Bullet point 1
- Bullet point 2

## Subtopic 2

More content...
```

#### Code Examples

````markdown
```swift
// Always specify language for syntax highlighting
func example() {
    print("Hello, World!")
}
```
````

#### Tables

```markdown
| Column 1 | Column 2 | Column 3 |
| -------- | -------- | -------- |
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |
```

## Troubleshooting

### markdownlint Not Found

Install markdownlint-cli:

```bash
# macOS with Homebrew
brew install markdownlint-cli

# With npm
npm install -g markdownlint-cli
```

### Configuration Not Loading

Check file location:

- `.markdownlint.yaml` in project root
- `.markdownlint.json` also supported
- Use `--config` flag to specify custom location

### False Positives

For intentional violations:

```markdown
<!-- markdownlint-disable MD013 -->

This is a very long line that is intentionally long and should not be wrapped.

<!-- markdownlint-enable MD013 -->
```

Disable for entire file:

```markdown
<!-- markdownlint-disable -->
```

## Tips and Tricks

### Quick Fixes

```bash
# Fix all files
task markdown:fix

# Fix specific file
markdownlint --fix README.md

# Check without fixing
task markdown:lint
```

### Useful Aliases

Add to shell configuration:

```bash
alias mdl="task markdown:lint"
alias mdf="task markdown:fix"
```

### Pre-push Validation

Always run before pushing:

```bash
task qa:quick  # Includes markdown linting
```
