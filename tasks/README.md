# Task Automation with go-task

This project uses [go-task](https://taskfile.dev/) (Task) as a task runner for automating development workflows. Task is a modern alternative to Make that uses simple YAML files to define tasks.

## What is go-task?

Task is a task runner / build tool that aims to be simpler and easier to use than GNU Make. It uses a simple YAML schema to define tasks and their dependencies, making it more readable and maintainable than traditional Makefiles.

## Installation

### macOS (via Homebrew)

```bash
brew install go-task/tap/go-task
```

### Other Platforms

See the [official installation guide](https://taskfile.dev/installation/) for other installation methods.

## Available Commands

To see all available tasks, run:

```bash
task --list-all
```

### Core Commands

| Command      | Description                        |
| ------------ | ---------------------------------- |
| `task`       | Show available tasks (default)     |
| `task init`  | Initialize development environment |
| `task run`   | Build and run MagSafe Guard        |
| `task test`  | Run all tests                      |
| `task clean` | Clean build artifacts              |

### Quality Assurance

| Command         | Description                  |
| --------------- | ---------------------------- |
| `task qa`       | Run standard QA checks       |
| `task qa:quick` | Quick checks (for git hooks) |
| `task qa:fix`   | Auto-fix all fixable issues  |
| `task qa:full`  | Full QA with SonarCloud      |

## Task Modules

The task system is organized into modules for better maintainability:

### 📦 [Swift Tasks](swift.md)

Swift development tasks including building, testing, linting, code coverage, and API documentation.

```bash
task swift:         # Show available Swift tasks
task swift:test     # Run tests
task swift:lint     # Run SwiftLint
task swift:docs     # Generate API documentation
```

### 🔒 [Security Tasks](security.md)

Security scanning and vulnerability detection tasks.

```bash
task security:         # Show available security tasks
task security:scan     # Run full security scan
task security:secrets  # Check for hardcoded secrets
```

### 📊 [SonarCloud Tasks](sonar.md)

Code quality analysis and SonarCloud integration.

```bash
task sonar:         # Show available SonarCloud tasks
task sonar:scan     # Run SonarCloud analysis
task sonar:simulate # Simulate analysis locally
```

### 📝 [Markdown Tasks](markdown.md)

Documentation linting and formatting tasks.

```bash
task markdown:      # Show available markdown tasks
task markdown:lint  # Lint markdown files
task markdown:fix   # Auto-fix markdown issues
```

### 🗃️ [Git Tasks](git.md)

Git repository management, GitHub integration, and PR comment analysis.

```bash
task git:           # Show available Git tasks
task git:pr:list    # List pull requests
task git:pr:comments # Download PR comments and security alerts
task git:cve:analyze # Analyze Dependabot vulnerabilities
```

### 🔧 [YAML Tasks](yaml.md)

YAML file validation and linting tasks.

```bash
task yaml:          # Show available YAML tasks
task yaml:lint      # Lint YAML files
task yaml:validate  # Validate YAML syntax
```

## Task File Structure

```ini
tasks/
├── README.md       # This file
├── git.yml         # Git and GitHub tasks
├── markdown.yml    # Markdown linting tasks
├── security.yml    # Security scanning tasks
├── sonar.yml       # SonarCloud analysis tasks
├── swift.yml       # Swift development tasks
├── yaml.yml        # YAML validation tasks
├── git.md          # Git module documentation
├── markdown.md     # Markdown module documentation
├── security.md     # Security module documentation
├── sonar.md        # SonarCloud module documentation
├── swift.md        # Swift module documentation
└── yaml.md         # YAML module documentation
```

## Creating Custom Tasks

Tasks are defined in YAML files. Here's a simple example:

```yaml
version: "3"

tasks:
  hello:
    desc: Say hello
    cmds:
      - echo "Hello, World!"
```

For more information on creating tasks, see the [Task documentation](https://taskfile.dev/).

## Tips

- Use `task <module>:` to see module-specific tasks (e.g., `task swift:`)
- Most commands have descriptions visible in `task --list`
- Tasks can have dependencies and run in parallel
- Variables and templates are supported for dynamic tasks
