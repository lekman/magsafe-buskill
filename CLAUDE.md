# Task Master AI - Claude Code Integration Guide

## 🎯 Core Development Strategy: Taskfile First

### Always Use Taskfile Commands

This project uses **Taskfile** (`task` command) as the primary interface for ALL development activities. When working on any task:

1. **Check available tasks first**: Run `task` to see main commands or `task --list` for all
2. **Use task commands** instead of direct tool invocations
3. **Module-specific tasks**: Use `task <module>:` to see module commands

Example workflow:
```bash
# ❌ Don't use direct commands
swift test
swiftlint
semgrep --config=auto

# ✅ Use task commands
task test
task swift:lint
task security:scan
```

### 🤖 AI Agent Integration

This project uses project-level Claude Code agents with specialized subagents. **Always prefer using subagents** for specific tasks rather than general agents.

**Quick Agent Commands:**
```bash
task ai                 # List all 24 AI commands
task ai:qa              # Run quality assurance on latest PR
task ai:architect       # Architecture review with subagents  
task ai:quick-check     # Fast P0/P1 issue scan
task ai:status          # Check agent reports
```

**Project-Level Agents and Their Subagents:**

#### @architect - Architecture Review

**Prefer these subagents for specific analysis:**
- `task ai:architect:solid-validator` - SOLID principles compliance
- `task ai:architect:security-architect` - Security architecture patterns
- `task ai:architect:ddd-analyzer` - Domain-driven design validation

#### @qa - Quality Assurance

**Prefer these subagents for targeted testing:**
- `task ai:qa:security-scanner` - Security vulnerability analysis
- `task ai:qa:coverage-analyzer` - Deep test coverage analysis
- `task ai:qa:performance-profiler` - Performance metrics and profiling

#### @author - Documentation

**Prefer these subagents for documentation tasks:**
- `task ai:author:api-docs` - API documentation generation
- `task ai:author:markdown-lint` - Markdown quality checking
- `task ai:author:diagram-gen` - Architecture diagram generation

#### @devops - Build & Deploy

**Prefer these subagents for infrastructure:**
- `task ai:devops:docker-optimizer` - Container optimization (N/A for macOS)
- `task ai:devops:k8s-validator` - Kubernetes validation (N/A for macOS)
- `task ai:devops:cost-analyzer` - Infrastructure cost analysis

**Best Practice:** Use specific subagents (e.g., `task ai:qa:security-scanner`) instead of general agents for more focused and effective analysis.

See `tasks/ai.yml` for implementation and `docs/ai/` for complete documentation.

## Essential Commands

### Core Workflow Commands

```bash
# Project Setup
task-master init                                    # Initialize Task Master in current project
task-master parse-prd .taskmaster/docs/prd.txt      # Generate tasks from PRD document
task-master models --setup                        # Configure AI models interactively

# Daily Development Workflow
task-master list                                   # Show all tasks with status
task-master next                                   # Get next available task to work on
task-master show <id>                             # View detailed task information (e.g., task-master show 1.2)
task-master set-status --id=<id> --status=done    # Mark task complete

# Task Management
task-master add-task --prompt="description" --research        # Add new task with AI assistance
task-master expand --id=<id> --research --force              # Break task into subtasks
task-master update-task --id=<id> --prompt="changes"         # Update specific task
task-master update --from=<id> --prompt="changes"            # Update multiple tasks from ID onwards
task-master update-subtask --id=<id> --prompt="notes"        # Add implementation notes to subtask

# Analysis & Planning
task-master analyze-complexity --research          # Analyze task complexity
task-master complexity-report                      # View complexity analysis
task-master expand --all --research               # Expand all eligible tasks

# Dependencies & Organization
task-master add-dependency --id=<id> --depends-on=<id>       # Add task dependency
task-master move --from=<id> --to=<id>                       # Reorganize task hierarchy
task-master validate-dependencies                            # Check for dependency issues
task-master generate                                         # Update task markdown files (usually auto-called)
```

## Key Files & Project Structure

### Core Files

- `.taskmaster/tasks/tasks.json` - Main task data file (auto-managed)
- `.taskmaster/config.json` - AI model configuration (use `task-master models` to modify)
- `.taskmaster/docs/prd.txt` - Product Requirements Document for parsing
- `.taskmaster/tasks/*.txt` - Individual task files (auto-generated from tasks.json)
- `.env` - API keys for CLI usage

### Claude Code Integration Files

- `CLAUDE.md` - Auto-loaded context for Claude Code (this file)
- `.claude/settings.json` - Claude Code tool allowlist and preferences
- `.claude/commands/` - Custom slash commands for repeated workflows
- `.mcp.json` - MCP server configuration (project-specific)

### Directory Structure

```ini
project/
├── .taskmaster/
│   ├── tasks/              # Task files directory
│   │   ├── tasks.json      # Main task database
│   │   ├── task-1.md      # Individual task files
│   │   └── task-2.md
│   ├── docs/              # Documentation directory
│   │   ├── prd.txt        # Product requirements
│   ├── reports/           # Analysis reports directory
│   │   └── task-complexity-report.json
│   ├── templates/         # Template files
│   │   └── example_prd.txt  # Example PRD template
│   └── config.json        # AI models & settings
├── .claude/
│   ├── agents/           # AI agent instructions
│   │   ├── architect.md  # Architecture review agent
│   │   ├── qa.md        # Quality assurance agent
│   │   ├── author.md    # Documentation agent
│   │   └── devops.md    # DevOps engineering agent
│   ├── settings.json    # Claude Code configuration
│   ├── commands/        # Custom slash commands
│   ├── collaboration.yml # Agent communication rules
│   └── schedule.yml     # Agent automation triggers
├── tasks/
│   ├── ai.yml           # AI agent task definitions
│   ├── swift.yml        # Swift development tasks
│   ├── security.yml     # Security scanning tasks
│   └── sonar.yml        # SonarCloud analysis tasks
├── docs/
│   └── ai/              # AI agent documentation
│       ├── README.md    # Quick start guide
│       └── *.md         # Detailed guides
├── .env                 # API keys
├── .mcp.json           # MCP configuration
└── CLAUDE.md           # This file - auto-loaded by Claude Code
```

## MCP Integration

Task Master provides an MCP server that Claude Code can connect to. Configure in `.mcp.json`:

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "your_key_here",
        "PERPLEXITY_API_KEY": "your_key_here",
        "OPENAI_API_KEY": "OPENAI_API_KEY_HERE",
        "GOOGLE_API_KEY": "GOOGLE_API_KEY_HERE",
        "XAI_API_KEY": "XAI_API_KEY_HERE",
        "OPENROUTER_API_KEY": "OPENROUTER_API_KEY_HERE",
        "MISTRAL_API_KEY": "MISTRAL_API_KEY_HERE",
        "AZURE_OPENAI_API_KEY": "AZURE_OPENAI_API_KEY_HERE",
        "OLLAMA_API_KEY": "OLLAMA_API_KEY_HERE"
      }
    }
  }
}
```

### Essential MCP Tools

```javascript
help; // = shows available taskmaster commands
// Project setup
initialize_project; // = task-master init
parse_prd; // = task-master parse-prd

// Daily workflow
get_tasks; // = task-master list
next_task; // = task-master next
get_task; // = task-master show <id>
set_task_status; // = task-master set-status

// Task management
add_task; // = task-master add-task
expand_task; // = task-master expand
update_task; // = task-master update-task
update_subtask; // = task-master update-subtask
update; // = task-master update

// Analysis
analyze_project_complexity; // = task-master analyze-complexity
complexity_report; // = task-master complexity-report
```

## Claude Code Workflow Integration

### Standard Development Workflow

#### 1. Project Initialization

```bash
# Initialize Task Master
task-master init

# Create or obtain PRD, then parse it
task-master parse-prd .taskmaster/docs/prd.txt

# Analyze complexity and expand tasks
task-master analyze-complexity --research
task-master expand --all --research
```

If tasks already exist, another PRD can be parsed (with new information only!) using parse-prd with --append flag. This will add the generated tasks to the existing list of tasks..

#### 2. Daily Development Loop

```bash
# Start each session
task-master next                           # Find next available task
task-master show <id>                     # Review task details

# During implementation, check in code context into the tasks and subtasks
task-master update-subtask --id=<id> --prompt="implementation notes..."

# Complete tasks
task-master set-status --id=<id> --status=done
```

#### 3. Multi-Claude Workflows

For complex projects, use multiple Claude Code sessions:

```bash
# Terminal 1: Main implementation
cd project && claude

# Terminal 2: Testing and validation
cd project-test-worktree && claude

# Terminal 3: Documentation updates
cd project-docs-worktree && claude
```

### Custom Slash Commands

Create `.claude/commands/taskmaster-next.md`:

```markdown
Find the next available Task Master task and show its details.

Steps:

1. Run `task-master next` to get the next task
2. If a task is available, run `task-master show <id>` for full details
3. Provide a summary of what needs to be implemented
4. Suggest the first implementation step
```

Create `.claude/commands/taskmaster-complete.md`:

```markdown
Complete a Task Master task: $ARGUMENTS

Steps:

1. Review the current task with `task-master show $ARGUMENTS`
2. Verify all implementation is complete
3. Run any tests related to this task
4. Mark as complete: `task-master set-status --id=$ARGUMENTS --status=done`
5. Show the next available task with `task-master next`
```

## Tool Allowlist Recommendations

Add to `.claude/settings.json`:

```json
{
  "allowedTools": [
    "Edit",
    "Bash(task *)",
    "Bash(task-master *)",
    "Bash(git commit:*)",
    "Bash(git add:*)",
    "Bash(npm run *)",
    "mcp__task_master_ai__*"
  ]
}
```

## Configuration & Setup

### API Keys Required

At least **one** of these API keys must be configured:

- `ANTHROPIC_API_KEY` (Claude models) - **Recommended**
- `PERPLEXITY_API_KEY` (Research features) - **Highly recommended**
- `OPENAI_API_KEY` (GPT models)
- `GOOGLE_API_KEY` (Gemini models)
- `MISTRAL_API_KEY` (Mistral models)
- `OPENROUTER_API_KEY` (Multiple models)
- `XAI_API_KEY` (Grok models)

An API key is required for any provider used across any of the 3 roles defined in the `models` command.

### Model Configuration

```bash
# Interactive setup (recommended)
task-master models --setup

# Set specific models
task-master models --set-main claude-3-5-sonnet-20241022
task-master models --set-research perplexity-llama-3.1-sonar-large-128k-online
task-master models --set-fallback gpt-4o-mini
```

## Task Structure & IDs

### Task ID Format

- Main tasks: `1`, `2`, `3`, etc.
- Subtasks: `1.1`, `1.2`, `2.1`, etc.
- Sub-subtasks: `1.1.1`, `1.1.2`, etc.

### Task Status Values

- `pending` - Ready to work on
- `in-progress` - Currently being worked on
- `done` - Completed and verified
- `deferred` - Postponed
- `cancelled` - No longer needed
- `blocked` - Waiting on external factors

### Task Fields

```json
{
  "id": "1.2",
  "title": "Implement user authentication",
  "description": "Set up JWT-based auth system",
  "status": "pending",
  "priority": "high",
  "dependencies": ["1.1"],
  "details": "Use bcrypt for hashing, JWT for tokens...",
  "testStrategy": "Unit tests for auth functions, integration tests for login flow",
  "subtasks": []
}
```

## Claude Code Best Practices with Task Master

### Context Management

- Use `/clear` between different tasks to maintain focus
- This CLAUDE.md file is automatically loaded for context
- Use `task-master show <id>` to pull specific task context when needed

### Iterative Implementation

1. `task-master show <subtask-id>` - Understand requirements
2. Explore codebase and plan implementation
3. `task-master update-subtask --id=<id> --prompt="detailed plan"` - Log plan
4. `task-master set-status --id=<id> --status=in-progress` - Start work
5. Implement code following logged plan
6. `task-master update-subtask --id=<id> --prompt="what worked/didn't work"` - Log progress
7. `task-master set-status --id=<id> --status=done` - Complete task

### Complex Workflows with Checklists

For large migrations or multi-step processes:

1. Create a markdown PRD file describing the new changes: `touch task-migration-checklist.md` (prds can be .txt or .md)
2. Use Taskmaster to parse the new prd with `task-master parse-prd --append` (also available in MCP)
3. Use Taskmaster to expand the newly generated tasks into subtasks. Consdier using `analyze-complexity` with the correct --to and --from IDs (the new ids) to identify the ideal subtask amounts for each task. Then expand them.
4. Work through items systematically, checking them off as completed
5. Use `task-master update-subtask` to log progress on each task/subtask and/or updating/researching them before/during implementation if getting stuck

### Git Integration

Task Master works well with `gh` CLI:

```bash
# Create PR for completed task
gh pr create --title "Complete task 1.2: User authentication" --body "Implements JWT auth system as specified in task 1.2"

# Reference task in commits
git commit -m "feat: implement JWT auth (task 1.2)"
```

### Parallel Development with Git Worktrees

```bash
# Create worktrees for parallel task development
git worktree add ../project-auth feature/auth-system
git worktree add ../project-api feature/api-refactor

# Run Claude Code in each worktree
cd ../project-auth && claude    # Terminal 1: Auth work
cd ../project-api && claude     # Terminal 2: API work
```

## Troubleshooting

### AI Commands Failing

```bash
# Check API keys are configured
cat .env                           # For CLI usage

# Verify model configuration
task-master models

# Test with different model
task-master models --set-fallback gpt-4o-mini
```

### MCP Connection Issues

- Check `.mcp.json` configuration
- Verify Node.js installation
- Use `--mcp-debug` flag when starting Claude Code
- Use CLI as fallback if MCP unavailable

### Task File Sync Issues

```bash
# Regenerate task files from tasks.json
task-master generate

# Fix dependency issues
task-master fix-dependencies
```

DO NOT RE-INITIALIZE. That will not do anything beyond re-adding the same Taskmaster core files.

## Important Notes

### AI-Powered Operations

These commands make AI calls and may take up to a minute:

- `parse_prd` / `task-master parse-prd`
- `analyze_project_complexity` / `task-master analyze-complexity`
- `expand_task` / `task-master expand`
- `expand_all` / `task-master expand --all`
- `add_task` / `task-master add-task`
- `update` / `task-master update`
- `update_task` / `task-master update-task`
- `update_subtask` / `task-master update-subtask`

### File Management

- Never manually edit `tasks.json` - use commands instead
- Never manually edit `.taskmaster/config.json` - use `task-master models`
- Task markdown files in `tasks/` are auto-generated
- Run `task-master generate` after manual changes to tasks.json

### Claude Code Session Management

- Use `/clear` frequently to maintain focused context
- Create custom slash commands for repeated Task Master workflows
- Configure tool allowlist to streamline permissions
- Use headless mode for automation: `claude -p "task-master next"`

### Multi-Task Updates

- Use `update --from=<id>` to update multiple future tasks
- Use `update-task --id=<id>` for single task updates
- Use `update-subtask --id=<id>` for implementation logging

### Research Mode

- Add `--research` flag for research-based AI enhancement
- Requires a research model API key like Perplexity (`PERPLEXITY_API_KEY`) in environment
- Provides more informed task creation and updates
- Recommended for complex technical tasks

## Testing Strategy

This project follows a protocol-based testing strategy to achieve high code coverage and maintain testability. See the comprehensive [Testing Guide](docs/maintainers/testing-guide.md) for detailed information.

### Quick Testing Commands

```bash
# Run tests with coverage
task test                # Uses SPM, generates coverage
task test:coverage       # Explicit coverage generation
task test:coverage:html  # Generate HTML coverage report

# Quality checks
task qa                  # Run all quality checks
task qa:quick            # Fast checks for git hooks
task qa:full             # Full suite with SonarCloud

# AI-powered analysis
task ai:qa               # AI agent analyzes latest PR
task ai:quick-check      # Fast P0/P1 issue detection
```

### CI Environment Parameters

The test suite recognizes these environment variables:

- **`CI=true`**: Enables CI mode for non-interactive testing

  - Skips authentication dialogs
  - Adjusts timeouts for CI environment
  - Enables additional logging
  - Prevents system actions (screen lock, etc.) during tests

- **`SKIP_UI_TESTS=true`**: Skip UI-dependent tests
- **`COVERAGE_THRESHOLD=80`**: Set minimum coverage requirement (default: 80%)

Example:

```bash
CI=true COVERAGE_THRESHOLD=85 task test
```

### Taskfile Testing Workflow

The project uses [Taskfile](https://taskfile.dev) for test automation:

- **`task test`**: Run all tests
- **`task test:coverage`**: Run tests and generate coverage report
- **`task test:coverage:html`**: Generate HTML coverage report
- **`task test:watch`**: Run tests in watch mode
- **`task test:convert`**: Convert LCOV to SonarQube format

The Taskfile handles:

- Coverage report generation with proper exclusions
- Format conversion for SonarCloud integration
- CI/CD environment detection
- Test result caching

### Testing Architecture

The codebase uses protocol-based dependency injection to separate:

- **Business Logic**: Fully testable with mocks (100% coverage target)
- **System Integration**: Thin layer excluded from coverage
- **Manual Acceptance Tests**: System features that require human validation

For more details, see the [Testing Guide](docs/maintainers/testing-guide.md).

## AI Agents Documentation

- **[AI Agents Overview](docs/ai/README.md)** - Quick start guide for AI agents
- **[Claude Agents Setup](docs/ai/claude-agents-setup.md)** - Complete setup instructions
- **[Agent Reference](docs/ai/agent-quick-reference.md)** - All agents and commands
- **[Subagents Guide](docs/ai/subagents-guide.md)** - Specialized subagent documentation

## Project Documentation

### Core Documentation

- **[Product Requirements](docs/PRD.md)** - Product requirements document
- **[Architecture Overview](docs/architecture/architecture-overview.md)** - System architecture
- **[Development Guide](docs/DEVELOPMENT.md)** - Development setup and workflow
- **[Security Guide](docs/SECURITY.md)** - Security implementation details

### Architecture Guides

- **[Menu Bar App Guide](docs/architecture/menu-bar-app-guide.md)** - macOS menu bar implementation
- **[Power Monitor Service](docs/architecture/power-monitor-service-guide.md)** - Power monitoring architecture
- **[Auth Flow Design](docs/architecture/auth-flow-design.md)** - Authentication flow details
- **[Settings Persistence](docs/architecture/settings-persistence-guide.md)** - Settings storage patterns

### Testing & Quality

- **[Testing Guide](docs/maintainers/testing-guide.md)** - Comprehensive testing strategy
- **[QA Guide](docs/QA.md)** - Quality assurance procedures
- **[Code Signing](docs/maintainers/code-signing.md)** - macOS code signing setup

---

## Working with Project-Level AI Agents

### 🎯 Subagent-First Strategy

This project uses **project-level agents** defined in `.claude/agents/`. **Always prefer specialized subagents** over general agents for more focused and effective analysis.

### Project Context

**MagSafe Guard** is a macOS menu bar security application using:
- Swift 6.0 with SwiftUI
- macOS 13+ target
- Swift Package Manager
- Clean Architecture with protocol-based dependency injection

### Agent Usage Guidelines

#### For Architecture Reviews
```bash
# Prefer specific subagents:
task ai:architect:solid-validator    # Check SOLID compliance
task ai:architect:security-architect # Review security patterns
task ai:architect:ddd-analyzer       # Validate domain design

# Instead of general:
task ai:architect                    # Use only for comprehensive review
```

#### For Quality Assurance
```bash
# Prefer targeted analysis:
task ai:qa:security-scanner          # Security vulnerabilities
task ai:qa:coverage-analyzer         # Test coverage gaps
task ai:qa:performance-profiler      # Performance metrics

# Instead of general:
task ai:qa                           # Use only for full QA suite
```

#### For Documentation
```bash
# Prefer specific tasks:
task ai:author:api-docs              # API documentation
task ai:author:markdown-lint         # Documentation quality
task ai:author:diagram-gen           # Architecture diagrams

# Instead of general:
task ai:author                       # Use only for full doc review
```

### MagSafe Guard Specific Examples

#### Example 1: Adding Power Monitoring Feature
```bash
# Use specific subagents in sequence:
task ai:architect:security-architect  # Review security implications
task ai:architect:ddd-analyzer        # Check domain boundaries
task ai:qa:coverage-analyzer          # Ensure test coverage
```

#### Example 2: Performance Optimization
```bash
# Targeted analysis:
task ai:qa:performance-profiler       # Identify bottlenecks
task ai:architect:solid-validator     # Check for violations
```

#### Example 3: Security Review
```bash
# Security-focused workflow:
task ai:qa:security-scanner           # Vulnerability scan
task ai:architect:security-architect  # Pattern review
task sonar:scan:pr                    # SonarCloud analysis
```

### Best Practices

1. **Use Subagents First**: They provide more focused, actionable results
2. **Chain Subagents**: Combine multiple subagents for comprehensive analysis
3. **PR-Focused**: The QA agent automatically analyzes the latest PR
4. **Task Integration**: All agents are integrated with the Taskfile workflow

### Agent Implementation Details

- **Location**: `.claude/agents/` contains all agent instructions
- **Templates**: `docs/templates/` contains report templates
- **Reports**: Agents generate `.*.review.md` files in project root
- **Automation**: See `.claude/schedule.yml` for automated triggers

---

## Important Instruction Reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (\*.md) or README files. Only create documentation files if explicitly requested by the User.
