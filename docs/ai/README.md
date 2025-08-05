# AI Agents Documentation

This directory contains documentation for Claude Code agents used in the MagSafe Guard project.

## Quick Start

```bash
# Run QA analysis on latest PR
task ai:qa

# Run architecture review
task ai:architect

# Check agent status
task ai:status

# Run all agents
task ai:all
```

## Documentation Files

- **[claude-agents-setup.md](claude-agents-setup.md)** - Complete setup guide for Claude Code agents
- **[agent-setup-instructions.md](agent-setup-instructions.md)** - Original detailed setup instructions
- **[agent-quick-reference.md](agent-quick-reference.md)** - Quick reference for all agents
- **[subagents-guide.md](subagents-guide.md)** - Guide to using specialized subagents

## Key Points

1. **Agent Location**: Agents are stored in `.claude/agents/` (not `.claude-agents/`)
2. **Task Integration**: Use `task ai:*` commands to invoke agents
3. **PR Analysis**: The QA agent automatically analyzes the latest PR
4. **Reports**: Agents generate `.*.review.md` files in the project root

## Available Agents

### Primary Agents
- `@architect` - Architecture and code quality review
- `@qa` - Quality assurance and testing
- `@author` - Documentation management
- `@devops` - Build and deployment optimization

### Subagents
Each primary agent has specialized subagents for focused analysis. See [subagents-guide.md](subagents-guide.md) for details.

## Task Commands

The `tasks/ai.yml` module provides 24 commands for agent operations:

```bash
# List all AI commands
task ai

# Primary agent commands
task ai:architect
task ai:qa
task ai:author
task ai:devops

# Workflow commands
task ai:all              # Run all agents
task ai:quick-check      # Fast P0/P1 check
task ai:pre-release      # Pre-release validation
task ai:security-audit   # Security focus

# Utility commands
task ai:status           # Check agent status
task ai:reports          # View all reports
task ai:clean            # Clean old reports
```

## Integration with CI/CD

Agents can be integrated into your development workflow:

1. **Pre-commit**: Run `task ai:quick-check`
2. **PR Review**: Run `task ai:qa` 
3. **Pre-release**: Run `task ai:pre-release`
4. **Weekly**: Run `task ai:all`

## Troubleshooting

If agents aren't working:

1. Check files are in `.claude/agents/`
2. Restart Claude Code
3. Verify GitHub CLI is authenticated for PR detection
4. Use task commands which have fallback behavior