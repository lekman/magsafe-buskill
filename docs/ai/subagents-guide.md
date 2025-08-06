# Claude Code Subagents: Advanced Agent Orchestration

## Overview

Subagents are specialized, focused agents that work under the coordination of primary agents. They handle specific, well-defined tasks and report back to their parent agents, enabling more granular and efficient analysis of your codebase.

## Current Implementation in MagSafe Guard

This project implements subagents through:

1. **Task Tool Integration** - Subagents accessible via Claude Code's Task tool
2. **Taskfile Commands** - `task ai:*` commands for direct invocation
3. **Global Agent Registration** - Agents available via `/agents` command when copied to `~/.claude/agents/`

## Understanding Subagents

### What are Subagents?

Subagents are:

- **Specialized** - Focused on specific tasks or technologies
- **Lightweight** - Designed for quick, targeted analysis
- **Composable** - Can be combined for complex workflows
- **Hierarchical** - Work under parent agents' coordination

### Benefits of Using Subagents

1. **Modularity** - Break complex tasks into manageable pieces
2. **Reusability** - Use the same subagent across different parent agents
3. **Performance** - Run only what's needed, when it's needed
4. **Clarity** - Clear separation of concerns and responsibilities
5. **Scalability** - Add new capabilities without modifying core agents

## Subagent Architecture

```mermaid
graph TD
    A[@architect] --> A1[Security Subagent]
    A --> A2[DDD Subagent]
    A --> A3[SOLID Subagent]

    Q[@qa] --> Q1[Unit Test Subagent]
    Q --> Q2[Integration Test Subagent]
    Q --> Q3[Performance Subagent]
    Q --> Q4[Security Scan Subagent]

    D[@devops] --> D1[Docker Subagent]
    D --> D2[Kubernetes Subagent]
    D --> D3[Terraform Subagent]

    AU[@author] --> AU1[API Docs Subagent]
    AU --> AU2[Markdown Lint Subagent]
    AU --> AU3[Diagram Generator Subagent]
```

## Available Subagents in MagSafe Guard

### Architect Subagents

- `task ai:architect:solid-validator` - SOLID principles compliance  
- `task ai:architect:security-architect` - Security architecture patterns
- `task ai:architect:ddd-analyzer` - Domain-driven design validation

### QA Subagents

- `task ai:qa:security-scanner` - Security vulnerability analysis
- `task ai:qa:coverage-analyzer` - Deep test coverage analysis  
- `task ai:qa:performance-profiler` - Performance metrics and profiling

### Author Subagents

- `task ai:author:api-docs` - API documentation generation
- `task ai:author:markdown-lint` - Markdown quality checking
- `task ai:author:diagram-gen` - Architecture diagram generation

### DevOps Subagents

- `task ai:devops:docker-optimizer` - Container optimization (N/A for macOS)
- `task ai:devops:k8s-validator` - Kubernetes validation (N/A for macOS)
- `task ai:devops:cost-analyzer` - Infrastructure cost analysis

## Creating Subagents

### Step 1: Define Subagent Structure

For new projects, create a subagents directory:

```bash
mkdir -p .claude/agents/subagents/{architect,qa,devops,author}
```

### Step 2: Create Subagent Templates

#### Example: Security Scanning Subagent

Create `.claude-agents/subagents/qa/security-scanner.md`:

````markdown
# Security Scanner Subagent

## Purpose

Specialized security analysis for the QA agent

## Responsibilities

1. Run SAST analysis
2. Check dependency vulnerabilities
3. Scan for secrets in code
4. Verify security headers
5. Check OWASP compliance

## Tools

- Snyk CLI
- SonarCloud Scanner
- git-secrets
- safety (Python)
- npm audit

## Output Format

```json
{
  "severity": "CRITICAL|HIGH|MEDIUM|LOW",
  "findings": [
    {
      "type": "vulnerability|secret|misconfiguration",
      "location": "file:line",
      "description": "Issue description",
      "fix": "Remediation steps"
    }
  ],
  "summary": {
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
```
````

## Integration

Reports to: @qa
Escalates to: @architect (for design flaws), @devops (for infrastructure issues)

`````markdown
#### Example: Test Coverage Analyzer Subagent

Create `.claude-agents/subagents/qa/coverage-analyzer.md`:

````markdown
# Test Coverage Analyzer Subagent

## Purpose

Deep analysis of test coverage metrics and gaps

## Responsibilities

1. Analyze coverage by module
2. Identify untested critical paths
3. Calculate complexity vs coverage ratio
4. Find dead code
5. Suggest test improvements

## Commands

```bash
task test:coverage:detailed
task test:coverage:report
task test:complexity:analysis
```
````
`````

````markdown
## Analysis Criteria

- Critical paths must have >95% coverage
- Complex functions (cyclomatic >10) need tests
- Public APIs require 100% coverage
- Integration points need E2E tests

## Output Format

```yaml
coverage:
  overall: 85.3%
  by_module:
    - name: auth
      coverage: 92.1%
      critical_gaps:
        - file: auth/validator.js
          lines: [45-67]
          risk: HIGH
  recommendations:
    - priority: P0
      action: "Add tests for auth validator edge cases"
      impact: "Prevents authentication bypass"
```
````

### Step 3: Register Subagents

Create `.claude-agents/subagents/registry.yml`:

```yaml
subagents:
  qa:
    security-scanner:
      description: "Specialized security analysis"
      trigger:
        - on_demand
        - schedule: "daily"
        - on_change: ["package.json", "requirements.txt", "go.mod"]

    coverage-analyzer:
      description: "Deep test coverage analysis"
      trigger:
        - on_demand
        - on_change: ["**/*.test.*", "**/*.spec.*"]
        - after: "test runs"

    performance-profiler:
      description: "Performance and load testing"
      trigger:
        - on_demand
        - before_release
        - schedule: "weekly"

  architect:
    solid-validator:
      description: "SOLID principles compliance"
      trigger:
        - on_change: ["src/**/*.{js,ts,java,cs}"]

    security-architect:
      description: "Security architecture patterns"
      trigger:
        - on_demand
        - on_change: ["**/auth*", "**/security*"]

    ddd-analyzer:
      description: "Domain-driven design validation"
      trigger:
        - on_change: ["domain/**", "application/**"]

  devops:
    docker-optimizer:
      description: "Docker image optimization"
      trigger:
        - on_change: ["**/Dockerfile*", "**/.dockerignore"]

    k8s-validator:
      description: "Kubernetes manifest validation"
      trigger:
        - on_change: ["k8s/**", "**/*.yaml"]

    cost-analyzer:
      description: "Cloud resource cost analysis"
      trigger:
        - schedule: "weekly"
        - on_demand
```

## Using Subagents in MagSafe Guard

### Method 1: Taskfile Commands (Recommended)

```bash
# Run specific subagents directly
task ai:architect:solid-validator
task ai:qa:security-scanner
task ai:qa:coverage-analyzer

# Run parent agents (which may delegate to subagents)
task ai:architect
task ai:qa
task ai:author
task ai:devops

# Quick checks
task ai:quick-check    # Fast P0/P1 issue scan
task ai:status         # Check agent reports
```

### Method 2: Claude Code Task Tool

In a Claude Code conversation, I can invoke subagents using the Task tool:

```markdown
"Please run the security scanner subagent on the circuit breaker implementation"
"Use the SOLID validator to check the resource protection code"
"Run coverage analysis on the security module"
```

### Method 3: Direct Agent Invocation (if globally registered)

After copying agents to `~/.claude/agents/`:

```bash
# In Claude Code chat
/agents                          # List available agents
@architect                       # Invoke architect agent
@qa                             # Invoke QA agent

# Or with specific instructions
@architect Review the circuit breaker implementation for SOLID compliance
@qa Run security scan on authentication module
```

### Method 4: Automated Workflows

Configure in `.claude/schedule.yml`:

```yaml
agents:
  architect:
    schedule: "0 9 * * MON"
    triggers:
      - pattern: "MagSafeGuardLib/Sources/**/*.swift"
        events: ["change"]
        threshold: 10
        
  qa:
    schedule: "0 9 * * *"
    triggers:
      - pattern: "**/*Tests.swift"
        events: ["change"]
```

### Method 5: Conditional Subagent Execution

Create `.claude/workflows/conditional-subagents.yml`:

```yaml
workflows:
  pre-release-check:
    steps:
      - agent: qa
        subagents:
          - name: coverage-analyzer
            condition: "coverage < 95%"
          - name: security-scanner
            condition: "always"
          - name: performance-profiler
            condition: "tag matches 'v*'"

      - agent: architect
        subagents:
          - name: security-architect
            condition: "qa/security-scanner found critical issues"
```

### Method 6: Interactive Subagent Usage in Claude Code

When chatting with Claude Code:

```markdown
User: "Run security scan on the authentication module"
Claude: [Uses Task tool to invoke qa:security-scanner subagent]

User: "Analyze test coverage for critical paths only"  
Claude: [Uses Task tool to invoke qa:coverage-analyzer with filters]

User: "Check all quality metrics before release"
Claude: [Orchestrates multiple subagents via Task tool]
```

Or with globally registered agents:

```markdown
User: "@qa run security scan on auth module"
User: "@architect validate SOLID principles in resource protection"
User: "@author check documentation coverage"
```

## Advanced Subagent Patterns

### 1. Subagent Pipelines in MagSafe Guard

The project implements pipelines through Taskfile workflows:

```yaml
pipeline: comprehensive-security-check
stages:
  - name: dependency-scan
    subagent: qa/dependency-scanner
    output: dependencies.json

  - name: code-scan
    subagent: qa/security-scanner
    input: dependencies.json
    output: vulnerabilities.json

  - name: architecture-review
    subagent: architect/security-architect
    input: vulnerabilities.json
    output: security-report.md

  - name: remediation-plan
    subagent: devops/security-patcher
    input: security-report.md
    output: remediation-tasks.json
```

Run pipeline through Taskfile:

```bash
# Pre-defined pipelines
task ai:qa           # Runs all QA subagents
task ai:pre-release  # Comprehensive pre-release checks
task ai:security     # Security-focused pipeline
```

### 2. Parallel Subagent Execution

In MagSafe Guard, parallel execution is handled by the Task tool:

```bash
# The QA agent runs multiple subagents in parallel
task ai:qa

# Or request parallel analysis in Claude Code:
"Run security scan, coverage analysis, and performance profiling in parallel"
```

Claude Code will use the Task tool to coordinate parallel execution.

### 3. Subagent Composition

Create composite subagents that use other subagents:

```markdown
# Composite Release Readiness Subagent

## Subagents Used

- qa/security-scanner
- qa/coverage-analyzer
- qa/performance-profiler
- architect/api-compatibility
- devops/deployment-validator

## Composition Logic

1. Run all QA subagents in parallel
2. If all pass, run architect subagents
3. If architect approves, run devops validation
4. Compile unified release report
```

### 4. Dynamic Subagent Usage in Claude Code

Request specific analysis dynamically:

```markdown
User: "Create a custom analysis for log4j vulnerabilities in our dependencies"
Claude: [Creates temporary subagent configuration and executes via Task tool]

User: "Check for hardcoded secrets in the new feature branch"  
Claude: [Configures security scanner with specific parameters]
```

## Subagent Communication

### Inter-Subagent Messaging

```yaml
# .claude-agents/subagents/communication.yml
messaging:
  security-scanner:
    publishes:
      - topic: "security.vulnerabilities"
      - topic: "security.critical"

  coverage-analyzer:
    subscribes:
      - topic: "security.critical"
        action: "prioritize coverage for security-critical code"

  security-architect:
    subscribes:
      - topic: "security.vulnerabilities"
        action: "analyze architectural implications"
    publishes:
      - topic: "architecture.security.recommendations"
```

### Subagent State Sharing

```bash
# Share state between subagent runs
claude-code subagent run qa/security-scanner --save-state

# Use saved state in another subagent
claude-code subagent run architect/security-architect --use-state qa/security-scanner
```

## Monitoring Subagents in MagSafe Guard

### Checking Agent Reports

```bash
# View latest agent reports
task ai:status

# Check specific report files
cat .architect.review.md
cat .qa.review.md
cat .devops.review.md

# View task execution logs
task --summary
```

### Debugging Subagents

```bash
# Run with verbose output
task ai:qa --verbose

# Check individual subagent results
ls -la .*.review.md

# View agent execution history in git
git log --oneline -- ".*.review.md"
```

## Best Practices

### 1. Subagent Design Principles

- **Single Responsibility**: Each subagent should do one thing well
- **Clear Interfaces**: Define input/output formats explicitly
- **Idempotent**: Running twice should produce same results
- **Fast Execution**: Target <30 seconds for most subagents
- **Clear Escalation**: Define when to involve parent agents

### 2. Naming Conventions

```text
{parent-agent}/{function}-{target}

Examples:
- qa/security-scanner
- qa/coverage-analyzer
- architect/solid-validator
- devops/docker-optimizer
```

### 3. Error Handling

```yaml
# Subagent error configuration
error_handling:
  security-scanner:
    on_tool_missing:
      action: "skip_with_warning"
      notify: "@devops"
    on_timeout:
      action: "retry"
      max_retries: 2
    on_critical_finding:
      action: "escalate"
      to: "@architect"
```

### 4. Version Control

```yaml
# Track subagent versions
subagent_versions:
  qa/security-scanner: "1.2.0"
  qa/coverage-analyzer: "1.1.0"

  changelog:
    qa/security-scanner:
      "1.2.0": "Added support for Go security scanning"
      "1.1.0": "Improved Python dependency analysis"
```

## Example: Complete Subagent Workflow

Here's a real-world example of subagents in action:

```bash
# 1. Developer pushes code
git push origin feature/payment-processing

# 2. Git hook triggers QA agent
claude-code agent run qa --trigger "code-push"

# 3. QA delegates to subagents based on changes
# Detects changes in payment module, runs:
# - qa/security-scanner (critical for payment code)
# - qa/coverage-analyzer (ensure thorough testing)
# - qa/pci-compliance (payment-specific)

# 4. Security scanner finds SQL injection risk
# Automatically escalates to architect/security-architect

# 5. Architect subagent analyzes and provides fix
# Creates task for developer

# 6. Results compiled into reports
# - .qa.review.md (updated with subagent findings)
# - .architecture.review.md (security recommendations)

# 7. Developer receives consolidated feedback
# All subagent findings in one place
```

## Conclusion

Subagents provide a powerful way to create modular, scalable, and maintainable agent systems. By breaking down complex analysis into focused subagents, you can:

- Build more sophisticated quality checks
- Improve performance through parallel execution
- Add new capabilities without modifying core agents
- Create clear, traceable analysis workflows
- Enable better collaboration between different aspects of your codebase

Start with a few essential subagents and expand as your needs grow. The modular nature of subagents means you can always add, modify, or remove them without disrupting your existing agent infrastructure.
