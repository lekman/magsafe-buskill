# Claude Code Agents Quick Reference

## Agent Overview

| Agent          | Focus Area            | Output File               | Key Responsibilities                               |
| -------------- | --------------------- | ------------------------- | -------------------------------------------------- |
| **@architect** | Architecture & Design | `.architecture.review.md` | Clean code, DDD, Security, PRD alignment, Tasks    |
| **@qa**        | Quality Assurance     | `.qa.review.md`           | Testing, Code quality, Security scans, Performance |
| **@author**    | Documentation         | Direct file updates       | Documentation coverage, quality, standards         |
| **@devops**    | Build & Deploy        | `.devops.review.md`       | CI/CD, Infrastructure, Security, Performance       |

## Quick Setup Commands

```bash
# 1. Create directories
mkdir -p docs/templates .claude-agents

# 2. Copy templates to docs/templates/
# - architect-template.md
# - qa-template.md
# - author-template.md
# - devops-template.md

# 3. Copy agent instructions to .claude-agents/
# - architect.md
# - qa.md
# - author.md
# - devops.md

# 4. Create agents
claude-code agent create architect --instructions .claude-agents/architect.md
claude-code agent create qa --instructions .claude-agents/qa.md
claude-code agent create author --instructions .claude-agents/author.md
claude-code agent create devops --instructions .claude-agents/devops.md

# 5. Run agents
claude-code agent run --all
```

## Key Files Structure

```
/
├── .architecture.review.md    # Architect's report
├── .qa.review.md             # QA's report
├── .devops.review.md         # DevOps report
├── docs/
│   ├── README.md             # Documentation index
│   ├── PRD.md               # Product requirements
│   ├── best-practice.md     # Documentation standards
│   ├── architecture/
│   │   └── best-practices.md
│   ├── security/
│   │   ├── authentication.md
│   │   ├── authorization.md
│   │   ├── data-protection.md
│   │   └── threat-model.md
│   └── templates/           # Agent templates
├── .taskmaster/             # Task definitions
├── Taskfile.yml            # Build tasks
└── .claude-agents/         # Agent configs
```

## Agent Collaboration Flow

```mermaid
graph LR
    A[@architect] -->|Quality Issues| Q[@qa]
    Q -->|Architecture Concerns| A
    A -->|Documentation Needs| D[@author]
    Q -->|Test Documentation| D
    D -->|DevOps Questions| O[@devops]
    O -->|Security Findings| A
    O -->|Pipeline Issues| Q
```

## Common Commands

### Running Agents

```bash
# Run all agents
claude-code agent run --all

# Run specific agent
claude-code agent run architect

# Quick check mode
claude-code agent run qa --quick-check

# Focus on specific area
claude-code agent run architect --focus security
```

### Task Commands (used by agents)

```bash
# Build and test
task build
task test:coverage
task lint:all

# Security
task security:scan
task sonar:analyze

# Git analysis
task git:failed-runs

# List all tasks
task --list-all
```

## Priority Levels

| Priority | Label    | Timeline    | Action                 |
| -------- | -------- | ----------- | ---------------------- |
| **P0**   | Critical | Immediate   | Block release, fix now |
| **P1**   | High     | This sprint | Must fix soon          |
| **P2**   | Medium   | Next sprint | Plan to address        |
| **P3**   | Low      | Backlog     | Nice to have           |

## Key Metrics Tracked

### Architect Metrics

- Clean Code Compliance %
- DDD Implementation Score
- Security Posture Rating
- PRD Alignment %

### QA Metrics

- Test Coverage %
- Build Success Rate
- Vulnerability Count
- Performance Benchmarks

### DevOps Metrics

- MTTD (Mean Time to Deploy)
- Deployment Frequency
- Change Failure Rate
- Pipeline Success Rate

## Review Schedule

| Day       | Agent(s)   | Focus                      |
| --------- | ---------- | -------------------------- |
| Monday    | @architect | Weekly architecture review |
| Tuesday   | @devops    | Pipeline optimization      |
| Wednesday | @author    | Documentation update       |
| Thursday  | @devops    | Security & performance     |
| Friday    | @qa        | Quality gate check         |
| Daily     | @qa        | Quick health check         |

## Troubleshooting

```bash
# Check agent status
claude-code agent status --all

# View logs
claude-code agent logs [agent-name] --tail 50

# Debug mode
claude-code agent run [agent-name] --debug

# Validate configuration
claude-code agent validate
```

## Best Practices

1. **Address P0 issues immediately** - They block releases
2. **Review reports in team meetings** - Share findings
3. **Update templates as needed** - Customize for your team
4. **Monitor trends, not just snapshots** - Track improvements
5. **Automate agent runs** - Use schedules or git hooks
