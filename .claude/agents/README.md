# Claude Code Agents Configuration

This directory contains the configuration for project-level Claude Code agents that continuously analyze and improve the MagSafe Guard codebase.

## Agents Overview

### 1. **@architect** - Architecture Review Agent
- **Focus**: Clean architecture, DDD, security patterns, PRD alignment
- **Output**: `.architecture.review.md`
- **Schedule**: Weekly on Mondays

### 2. **@qa** - Quality Assurance Agent
- **Focus**: Test coverage, code quality, security scans, performance
- **Output**: `.qa.review.md`
- **Schedule**: Daily

### 3. **@author** - Technical Documentation Agent
- **Focus**: Documentation coverage, quality, and standards
- **Output**: Direct documentation file updates
- **Schedule**: Weekly on Wednesdays

### 4. **@devops** - DevOps Engineering Agent
- **Focus**: CI/CD, build optimization, security, infrastructure
- **Output**: `.devops.review.md`
- **Schedule**: Twice weekly (Tuesday/Thursday)

## Configuration Files

- **`architect.md`** - Instructions for the architecture review agent
- **`qa.md`** - Instructions for the quality assurance agent
- **`author.md`** - Instructions for the documentation agent
- **`devops.md`** - Instructions for the DevOps agent
- **`schedule.yml`** - Automated trigger schedules and file patterns
- **`collaboration.yml`** - Inter-agent communication rules

## Templates

Agent templates are located in `docs/templates/`:
- `architect-template.md`
- `qa-template.md`
- `author-template.md`
- `devops-template.md`

## Usage

### Manual Agent Execution
```bash
# Run individual agents
claude agent run architect
claude agent run qa
claude agent run author
claude agent run devops

# Run all agents
claude agent run --all

# Run with specific focus
claude agent run architect --focus security
claude agent run qa --focus coverage
```

### Check Agent Status
```bash
# View agent activity
claude agent status --all

# View agent logs
claude agent logs architect --tail 50

# Debug mode
claude agent run architect --debug
```

## Priority Levels

- **P0 (Critical)**: Block release, fix immediately
- **P1 (High)**: Must fix this sprint
- **P2 (Medium)**: Plan for next sprint
- **P3 (Low)**: Backlog item

## Integration with MagSafe Guard

The agents are specifically configured for the MagSafe Guard project:
- Swift/macOS development patterns
- Clean Architecture principles
- Security-first approach
- Comprehensive test coverage requirements

## Maintenance

- Review agent outputs weekly
- Address P0/P1 issues immediately
- Update templates based on project evolution
- Monitor agent effectiveness metrics