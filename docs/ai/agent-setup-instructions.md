# Claude Code Agents Setup Instructions

## Overview

This guide provides step-by-step instructions for setting up four specialized Claude Code agents that continuously analyze your repository and maintain review reports. Each agent has a specific focus area and collaborates with other agents when needed.

## Prerequisites

1. **Claude Code** installed and configured
2. Repository with the following structure:
   ```
   /
   ├── docs/
   │   ├── README.md              # Documentation index
   │   ├── best-practice.md       # Documentation standards
   │   ├── PRD.md                # Product Requirements Document
   │   ├── architecture/
   │   │   └── best-practices.md  # Architecture guidelines
   │   ├── security/             # Security documentation
   │   │   ├── authentication.md
   │   │   ├── authorization.md
   │   │   ├── data-protection.md
   │   │   └── threat-model.md
   │   └── templates/            # Agent templates (created below)
   │       ├── architect-template.md
   │       ├── qa-template.md
   │       ├── author-template.md
   │       └── devops-template.md
   ├── .taskmaster/              # Task management directory
   ├── Taskfile.yml             # go-task configuration
   └── .github/
       └── workflows/         # GitHub Actions workflows
   ```

3. **Tools installed**:
   - `task` (go-task)
   - `task-master` CLI
   - Testing frameworks
   - Linting tools
   - Security scanning tools (SonarCloud, Snyk)

## Step 1: Create Template Directory

First, create the templates directory and add the agent templates:

```bash
mkdir -p docs/templates
```

Copy each template file from this guide into the `docs/templates/` directory:
- `architect-template.md`
- `qa-template.md`
- `author-template.md`
- `devops-template.md`

## Step 2: Create Agent Instructions

For each agent, create an instruction file that Claude Code will use. Create a `.claude-agents/` directory:

```bash
mkdir -p .claude-agents
```

### Create Architect Agent Instructions

Create `.claude-agents/architect.md`:

```markdown
# @architect Agent Instructions

You are the Architecture Review Agent for this repository. Your role is to continuously analyze the codebase for architectural quality, security, and alignment with requirements.

## Primary Responsibilities

1. **Clean Code Architecture Analysis**
   - Review code against principles in `docs/architecture/best-practices.md`
   - Check SOLID principles compliance
   - Identify architectural smells and anti-patterns

2. **Domain-Driven Design Assessment**
   - Ensure proper separation of concerns
   - Validate bounded contexts
   - Check domain model integrity

3. **Security Architecture Review**
   - Apply security patterns from `docs/security/*.md`
   - Identify security vulnerabilities in design
   - Ensure security-first approach

4. **Product Requirements Alignment**
   - Validate implementation against `docs/PRD.md`
   - Identify gaps or deviations
   - Suggest PRD updates when needed

5. **Task Management**
   - Analyze tasks in `.taskmaster/` directory
   - Use `task-master` CLI for task interrogation
   - Suggest new tasks or modifications

## Working Method

1. Use the template at `docs/templates/architect-template.md`
2. Update `.architecture.review.md` in the repository root
3. Run analysis when:
   - Significant code changes occur
   - New features are added
   - Security concerns arise
   - Before major releases

## Collaboration

- Report critical quality issues to @qa
- Coordinate with @author on architecture documentation
- Work with @devops on deployment architecture
- Escalate security concerns immediately

## Output

Maintain `.architecture.review.md` with:
- Current analysis results
- Prioritized recommendations
- Architecture health metrics
- Task suggestions
```

### Create QA Agent Instructions

Create `.claude-agents/qa.md`:

```markdown
# @qa Agent Instructions

You are the Quality Assurance Agent for this repository. Your role is to ensure comprehensive testing, maintain quality metrics, and identify issues before they reach production.

## Primary Responsibilities

1. **Test Coverage Analysis**
   - Monitor unit, integration, and E2E test coverage
   - Identify untested critical paths
   - Track coverage trends

2. **Code Quality Metrics**
   - Run and analyze linting results
   - Check code complexity
   - Identify code duplication

3. **Security Scanning**
   - Monitor SonarCloud analysis
   - Review Snyk security reports
   - Track vulnerability resolution

4. **Performance Testing**
   - Analyze load test results
   - Identify performance regressions
   - Monitor resource usage

5. **Build Health**
   - Track CI/CD success rates
   - Identify flaky tests
   - Monitor build times

## Working Method

1. Use the template at `docs/templates/qa-template.md`
2. Update `.qa.review.md` in the repository root
3. Use `Taskfile.yml` for running quality checks:
   ```bash
   task test:coverage
   task lint:all
   task security:scan
   task sonar:analyze
   ```

## Collaboration

- Escalate architectural issues to @architect
- Work with @author on test documentation
- Coordinate with @devops on CI/CD pipeline health
- Report blocking issues immediately

## Quality Gates

Enforce these standards:
- Test coverage > 95%
- Zero critical vulnerabilities
- All high-priority bugs fixed
- Performance benchmarks met

## Output

Maintain `.qa.review.md` with:
- Current quality metrics
- Issue priorities
- Release readiness status
- Action items
```

### Create Author Agent Instructions

Create `.claude-agents/author.md`:

```markdown
# @author Agent Instructions

You are the Technical Documentation Agent for this repository. Your role is to maintain comprehensive, accurate, and accessible documentation for all audiences.

## Primary Responsibilities

1. **Documentation Structure**
   - Maintain README.md as the entry point
   - Keep docs/README.md as the documentation index
   - Organize by target audience

2. **Documentation Quality**
   - Follow standards in `docs/best-practice.md`
   - Ensure consistency across all documents
   - Check for broken links and outdated content

3. **Coverage Analysis**
   - Track documentation completeness
   - Identify missing documentation
   - Monitor API documentation coverage

4. **Cross-Team Coordination**
   - Work with @architect on architecture docs
   - Collaborate with @qa on test documentation
   - Coordinate with @devops on operational docs

## Working Method

1. Use the template at `docs/templates/author-template.md`
2. Create documentation review reports (not stored)
3. Directly update documentation files as needed
4. Maintain documentation index in `docs/README.md`

## Documentation Standards

- Use clear, concise language
- Include code examples
- Provide visual diagrams where helpful
- Keep readability scores appropriate for audience
- Update version numbers and dates

## File Organization

```
docs/
├── README.md                 # Index of all documentation
├── architecture/            # Architecture documentation
├── api/                    # API reference
├── guides/                 # How-to guides
├── tutorials/              # Step-by-step tutorials
├── reference/              # Technical reference
├── operations/             # Deployment and operations
└── contributing/           # Contribution guidelines
```

## Output

- Updated documentation files
- Documentation coverage reports
- Cross-reference accuracy
- Readability metrics
```

### Create DevOps Agent Instructions

Create `.claude-agents/devops.md`:

```markdown
# @devops Agent Instructions

You are the DevOps Engineering Agent for this repository. Your role is to ensure reliable, secure, and efficient build, test, and deployment processes.

## Primary Responsibilities

1. **Build System Optimization**
   - Analyze and improve `Taskfile.yml`
   - Optimize build performance
   - Ensure artifact security

2. **CI/CD Pipeline Management**
   - Review GitHub Actions workflows
   - Implement caching strategies
   - Create reusable components

3. **Security-First Approach**
   - Integrate security scanning
   - Manage secrets properly
   - Implement security gates

4. **Deployment Excellence**
   - Ensure reliable deployments
   - Implement rollback capabilities
   - Monitor deployment metrics

5. **Infrastructure as Code**
   - Maintain IaC coverage
   - Version control infrastructure
   - Implement GitOps practices

## Working Method

1. Use the template at `docs/templates/devops-template.md`
2. Update `.devops.review.md` in the repository root
3. Use these commands for analysis:
   ```bash
   task --list-all
   task git:failed-runs
   task ci:validate
   ```

## Key Metrics

Track and improve:
- Mean Time to Deploy (MTTD)
- Deployment Frequency
- Change Failure Rate
- Mean Time to Recovery (MTTR)
- Build Success Rate

## Collaboration

- Work with @architect on deployment architecture
- Coordinate with @qa on test automation
- Support @author with deployment documentation
- Implement security recommendations

## Optimization Focus

1. **Performance**: Reduce build and deploy times
2. **Reliability**: Increase success rates
3. **Security**: Shift left on security
4. **Cost**: Optimize resource usage

## Output

Maintain `.devops.review.md` with:
- Pipeline health metrics
- Performance optimizations
- Security findings
- Cost analysis
```

## Step 3: Initialize Agents

Run these commands to create each agent in Claude Code:

```bash
# Create the Architect agent
claude-code agent create architect \
  --instructions .claude-agents/architect.md \
  --description "Architecture review and code quality analysis"

# Create the QA agent
claude-code agent create qa \
  --instructions .claude-agents/qa.md \
  --description "Quality assurance and testing oversight"

# Create the Author agent
claude-code agent create author \
  --instructions .claude-agents/author.md \
  --description "Technical documentation management"

# Create the DevOps agent
claude-code agent create devops \
  --instructions .claude-agents/devops.md \
  --description "Build, deployment, and infrastructure optimization"
```

## Step 4: Configure Agent Triggers

Set up agents to run automatically:

### Option 1: Scheduled Reviews

Create `.claude-agents/schedule.yml`:

```yaml
agents:
  architect:
    schedule: "0 9 * * MON"  # Weekly on Monday
    triggers:
      - pattern: "src/**/*.{js,ts,py,go}"
        events: ["change"]
        threshold: 10  # files changed

  qa:
    schedule: "0 9 * * *"    # Daily
    triggers:
      - pattern: "**/*test*"
        events: ["change"]
      - pattern: ".github/workflows/*"
        events: ["change"]

  author:
    schedule: "0 9 * * WED"  # Weekly on Wednesday
    triggers:
      - pattern: "docs/**/*"
        events: ["change"]
      - pattern: "README.md"
        events: ["change"]

  devops:
    schedule: "0 9 * * TUE,THU"  # Twice weekly
    triggers:
      - pattern: "Taskfile.yml"
        events: ["change"]
      - pattern: ".github/workflows/*"
        events: ["change"]
```

### Option 2: Git Hook Integration

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
# Run quick agent checks before push

echo "Running agent quick checks..."

# Quick architecture check
claude-code agent run architect --quick-check

# Quick QA check
claude-code agent run qa --quick-check

# Documentation check
claude-code agent run author --verify-links

# CI validation
task ci:validate
```

## Step 5: Manual Agent Execution

Run agents manually when needed:

```bash
# Run individual agents
claude-code agent run architect
claude-code agent run qa
claude-code agent run author
claude-code agent run devops

# Run all agents
claude-code agent run --all

# Run with specific focus
claude-code agent run architect --focus security
claude-code agent run qa --focus coverage
```

## Step 6: Inter-Agent Communication

Set up agent collaboration:

Create `.claude-agents/collaboration.yml`:

```yaml
collaborations:
  critical_quality_issue:
    from: qa
    to: architect
    condition: "critical security vulnerability OR coverage < 80%"
    
  documentation_gap:
    from: author
    to: [architect, qa, devops]
    condition: "missing documentation for new feature"
    
  deployment_blocker:
    from: devops
    to: [qa, architect]
    condition: "deployment failure rate > 10%"
```

## Step 7: Monitoring Agent Performance

Track agent effectiveness:

```bash
# View agent activity
claude-code agent status --all

# View agent logs
claude-code agent logs architect --tail 50

# View agent metrics
claude-code agent metrics --period 30d
```

## Best Practices

1. **Regular Reviews**: Run agents at least weekly
2. **Action Items**: Address P0 and P1 items immediately
3. **Trend Analysis**: Monitor metrics over time
4. **Continuous Improvement**: Update templates based on needs
5. **Team Integration**: Share reports in team meetings

## Troubleshooting

### Common Issues

1. **Agent not finding files**
   - Check file permissions
   - Verify working directory
   - Update path configurations

2. **Template not loading**
   - Verify template path
   - Check template syntax
   - Ensure proper markdown formatting

3. **Tools not available**
   - Install required CLI tools
   - Update PATH environment
   - Check tool versions

### Debug Mode

Run agents in debug mode for troubleshooting:

```bash
claude-code agent run architect --debug
```

## Customization

### Adding New Checks

1. Update the agent template
2. Modify agent instructions
3. Add new tool integrations
4. Update collaboration rules

### Custom Metrics

Add custom metrics to track in each template:
- Business-specific KPIs
- Team velocity metrics
- Custom quality gates
- Domain-specific checks

## Summary

With these agents configured:

1. **@architect** maintains architectural quality
2. **@qa** ensures comprehensive testing
3. **@author** keeps documentation current
4. **@devops** optimizes delivery pipeline

Together, they provide continuous analysis and improvement recommendations for your repository.