# Claude Code Subagents: Advanced Agent Orchestration

## Overview

Subagents are specialized, focused agents that work under the coordination of primary agents. They handle specific, well-defined tasks and report back to their parent agents, enabling more granular and efficient analysis of your codebase.

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

## Creating Subagents

### Step 1: Define Subagent Structure

Create a subagents directory:

```bash
mkdir -p .claude-agents/subagents/{architect,qa,devops,author}
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

## Using Subagents

### Method 1: Direct Subagent Invocation

```bash
# Run a specific subagent
claude-code subagent run qa/security-scanner

# Run with parameters
claude-code subagent run qa/coverage-analyzer --module auth

# Run multiple subagents
claude-code subagent run qa/security-scanner qa/coverage-analyzer
```

### Method 2: Parent Agent Delegation

```bash
# Parent agent automatically delegates to subagents
claude-code agent run qa --deep-analysis

# Specific subagent through parent
claude-code agent run qa --subagent security-scanner

# Chain subagents
claude-code agent run qa --subagents "security-scanner,coverage-analyzer"
```

### Method 3: Conditional Subagent Execution

Create `.claude-agents/workflows/conditional-subagents.yml`:

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

### Method 4: Interactive Subagent Usage

```bash
# Start interactive session
claude-code chat qa

> run security scan on the authentication module
# QA automatically delegates to security-scanner subagent

> analyze test coverage for critical paths only
# QA uses coverage-analyzer subagent with filters

> check all quality metrics before release
# QA orchestrates multiple subagents
```

## Advanced Subagent Patterns

### 1. Subagent Pipelines

Create `.claude-agents/pipelines/security-pipeline.yml`:

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

Run pipeline:

```bash
claude-code pipeline run comprehensive-security-check
```

### 2. Parallel Subagent Execution

```bash
# Run subagents in parallel for faster analysis
claude-code agent run qa --parallel-subagents "security-scanner,coverage-analyzer,performance-profiler"

# With resource limits
claude-code agent run qa --parallel-subagents all --max-concurrent 3
```

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

### 4. Dynamic Subagent Creation

```bash
# Create temporary subagent for specific analysis
claude-code subagent create-temp \
  --name "log4j-scanner" \
  --parent qa \
  --task "scan for log4j vulnerabilities" \
  --expires "24h"
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

## Monitoring Subagents

### Performance Metrics

```bash
# View subagent performance
claude-code subagent metrics qa/security-scanner

# Compare subagent efficiency
claude-code subagent compare qa/*

# Resource usage
claude-code subagent resources --last-run
```

### Debugging Subagents

```bash
# Debug mode
claude-code subagent run qa/security-scanner --debug

# Trace execution
claude-code subagent trace qa/coverage-analyzer

# View subagent logs
claude-code subagent logs qa/security-scanner --tail 100
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
