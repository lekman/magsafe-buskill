# AI Tasks Module

The AI tasks module provides a comprehensive interface for running Claude Code agents and subagents to continuously analyze and improve the MagSafe Guard codebase.

## Quick Start

```bash
# List all AI tasks
task ai

# Run all QA checks
task ai:qa

# Run specific subagent
task ai:qa:security-scanner

# Quick security check
task ai:quick-check

# Pre-release validation
task ai:pre-release
```

## Available Commands

### Primary Agents

| Command             | Description                                 |
| ------------------- | ------------------------------------------- |
| `task ai:architect` | Run architecture review agent               |
| `task ai:qa`        | Run quality assurance agent (all subagents) |
| `task ai:author`    | Run documentation agent                     |
| `task ai:devops`    | Run DevOps engineering agent                |

### QA Subagents

| Command                           | Description                       |
| --------------------------------- | --------------------------------- |
| `task ai:qa:security-scanner`     | Security vulnerability analysis   |
| `task ai:qa:coverage-analyzer`    | Test coverage deep analysis       |
| `task ai:qa:performance-profiler` | Performance testing and profiling |

### Architect Subagents

| Command                                | Description                     |
| -------------------------------------- | ------------------------------- |
| `task ai:architect:solid-validator`    | SOLID principles compliance     |
| `task ai:architect:security-architect` | Security architecture patterns  |
| `task ai:architect:ddd-analyzer`       | Domain-driven design validation |

### DevOps Subagents

| Command                           | Description                    |
| --------------------------------- | ------------------------------ |
| `task ai:devops:docker-optimizer` | Docker image optimization      |
| `task ai:devops:k8s-validator`    | Kubernetes manifest validation |
| `task ai:devops:cost-analyzer`    | Cloud resource cost analysis   |

### Author Subagents

| Command                        | Description                     |
| ------------------------------ | ------------------------------- |
| `task ai:author:api-docs`      | API documentation generation    |
| `task ai:author:markdown-lint` | Markdown quality check          |
| `task ai:author:diagram-gen`   | Architecture diagram generation |

### Workflows

| Command                  | Description                            |
| ------------------------ | -------------------------------------- |
| `task ai:all`            | Run all agents sequentially            |
| `task ai:quick-check`    | Fast quality check (P0/P1 issues only) |
| `task ai:pre-release`    | Comprehensive pre-release validation   |
| `task ai:security-audit` | Full security audit pipeline           |

### Reporting

| Command           | Description                          |
| ----------------- | ------------------------------------ |
| `task ai:status`  | Show agent status and last run times |
| `task ai:reports` | View all generated reports           |
| `task ai:clean`   | Clean up old reports                 |

## Integration with Claude Code

The AI tasks module is designed to work with Claude Code agents. When Claude CLI is available, it will use the actual agents. When not available, it provides useful simulations and runs available tools.

### Agent Configuration

Agent configurations are stored in:

- `.claude-agents/` - Agent instructions and configuration
- `docs/templates/` - Agent report templates

### Generated Reports

Agents generate the following reports:

- `.architecture.review.md` - Architecture analysis
- `.qa.review.md` - Quality assurance findings
- `.devops.review.md` - DevOps metrics and recommendations

## Usage Examples

### Daily Quality Check

```bash
# Run quick quality check
task ai:quick-check
```

### Before Release

```bash
# Run comprehensive pre-release validation
task ai:pre-release
```

### Security Audit

```bash
# Run full security audit
task ai:security-audit
```

### Check Specific Area

```bash
# Check test coverage
task ai:qa:coverage-analyzer

# Validate SOLID principles
task ai:architect:solid-validator

# Review security architecture
task ai:architect:security-architect
```

## Features

- **Modular Design**: Each agent and subagent focuses on specific concerns
- **Fallback Support**: Works without Claude CLI by using available tools
- **Comprehensive Coverage**: Covers architecture, quality, security, and operations
- **Actionable Reports**: Generates prioritized recommendations
- **Integration Ready**: Works with existing CI/CD pipelines

## Priority Levels

Reports use the following priority levels:

- **P0 (Critical)**: Block release, fix immediately
- **P1 (High)**: Must fix this sprint
- **P2 (Medium)**: Plan for next sprint
- **P3 (Low)**: Backlog item

## Maintenance

- Review agent outputs weekly
- Address P0/P1 issues immediately
- Update agent configurations as needed
- Monitor agent effectiveness metrics
