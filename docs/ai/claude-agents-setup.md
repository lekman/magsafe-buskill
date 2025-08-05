# Claude Code Agents Setup Guide

## Overview

This guide explains how to set up and use Claude Code agents for continuous code analysis in the MagSafe Guard project.

## Directory Structure

Claude Code agents must be placed in the `.claude/agents/` directory (not `.claude-agents/`):

```ini
.claude/
├── agents/                 # Agent instruction files
│   ├── architect.md       # Architecture review agent
│   ├── qa.md             # Quality assurance agent
│   ├── author.md         # Documentation agent
│   └── devops.md         # DevOps engineering agent
├── commands/              # Custom slash commands
├── settings.json         # Claude Code settings
├── collaboration.yml     # Inter-agent communication rules
└── schedule.yml         # Automated agent triggers
```

## Agent Files Created

### Primary Agents

1. **@architect** (`.claude/agents/architect.md`)

   - Reviews architecture quality
   - Validates SOLID principles
   - Checks security patterns
   - Aligns with PRD requirements

2. **@qa** (`.claude/agents/qa.md`)

   - Runs comprehensive quality checks
   - Analyzes test coverage
   - Performs security scanning
   - Reviews performance metrics

3. **@author** (`.claude/agents/author.md`)

   - Maintains documentation
   - Checks documentation coverage
   - Validates API documentation
   - Ensures consistency

4. **@devops** (`.claude/agents/devops.md`)
   - Optimizes build systems
   - Reviews CI/CD pipelines
   - Analyzes deployment metrics
   - Implements security gates

## How to Use Agents

### Via Task Commands

The `tasks/ai.yml` module provides convenient commands to invoke agents:

```bash
# Run QA agent with latest PR context
task ai:qa

# Run architecture review
task ai:architect

# Run all agents
task ai:all

# Quick security check
task ai:quick-check
```

### Direct Claude Code Usage

When Claude Code is restarted, agents become available as personas:

```bash
# In Claude Code, you can reference agents
@qa please analyze the latest PR
@architect review the domain layer architecture
```

### Task Command Features

The task commands automatically:

- Detect the latest PR number
- Pass context to agents
- Run prerequisite commands (like SonarCloud analysis)
- Provide fallback behavior when Claude CLI isn't available

## Agent Subagents

Each primary agent can invoke specialized subagents:

### QA Subagents

- `@qa:security-scanner` - Security vulnerability analysis
- `@qa:coverage-analyzer` - Deep test coverage analysis
- `@qa:performance-profiler` - Performance testing

### Architect Subagents

- `@architect:solid-validator` - SOLID principles compliance
- `@architect:security-architect` - Security patterns review
- `@architect:ddd-analyzer` - Domain-driven design validation

### DevOps Subagents

- `@devops:docker-optimizer` - Container optimization
- `@devops:k8s-validator` - Kubernetes validation
- `@devops:cost-analyzer` - Cloud cost analysis

### Author Subagents

- `@author:api-docs` - API documentation generation
- `@author:markdown-lint` - Markdown quality check
- `@author:diagram-gen` - Architecture diagrams

## Integration with PR Analysis

The QA agent is specially configured to analyze pull requests:

```bash
# Automatically detects and analyzes latest PR
task ai:qa

# Behind the scenes, this:
# 1. Gets latest PR number (e.g., #28)
# 2. Runs: task sonar:scan:pr PR=28
# 3. Invokes @qa agent with PR context
# 4. Uses subagents for comprehensive analysis
# 5. Generates .qa.review.md report
```

## Report Files

Agents generate reports in the project root:

- `.architecture.review.md` - Architecture analysis
- `.qa.review.md` - Quality assurance findings
- `.devops.review.md` - DevOps metrics and recommendations

## Troubleshooting

### Agents Not Available in Claude Code

1. Ensure files are in `.claude/agents/` (not `.claude-agents/`)
2. Restart Claude Code to load new agents
3. Check file permissions are readable

### Task Commands Not Finding Claude CLI

The task commands include fallback behavior:

- They'll run available tools directly
- Generate basic reports without AI analysis
- Still provide useful output

### PR Detection Not Working

Requires GitHub CLI (`gh`) to be installed and authenticated:

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

## Best Practices

1. **Regular Analysis**: Run agents weekly or before releases
2. **PR-Focused**: Always analyze latest PR for relevant feedback
3. **Action Items**: Address P0/P1 findings immediately
4. **Trend Tracking**: Monitor metrics over time
5. **Team Integration**: Share reports in team meetings

## Next Steps

1. Run `task ai:status` to verify setup
2. Try `task ai:qa` to analyze the latest PR
3. Review generated reports
4. Customize agent instructions as needed
