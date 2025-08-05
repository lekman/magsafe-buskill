# AI Integration Setup Guide

This guide covers setting up AI integrations for the MagSafe Guard project, including Sentry MCP integration and Task Master AI.

## Prerequisites

- [Claude Code CLI](https://claude.ai/code) installed
- [Node.js](https://nodejs.org/) (for MCP servers)
- API keys for required services

## Sentry MCP Integration

### 1. Environment Variables

Add these to your `.env` file (copy from `.env.example`):

```bash
# Sentry Configuration for MagSafe Guard
SENTRY_DSN=https://e74a158126b00e128ebdda98f6a36b76@o4509752039243776.ingest.de.sentry.io/4509752042127440
SENTRY_ENABLED=true
SENTRY_ENVIRONMENT=development
SENTRY_DEBUG=true
SENTRY_TOKEN=your_sentry_auth_token_here
```

### 2. MCP Configuration

Create `.mcp.json` in the project root:

```json
{
  "mcpServers": {
    "task-master-ai": {
      "command": "npx",
      "args": ["-y", "--package=task-master-ai", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "your_anthropic_api_key",
        "PERPLEXITY_API_KEY": "your_perplexity_api_key"
      }
    },
    "sentry": {
      "command": "npx", 
      "args": ["-y", "--package=@mcp-integrations/sentry", "mcp-sentry-server"],
      "env": {
        "SENTRY_ORG": "lekman-consulting",
        "SENTRY_PROJECT": "magsafeguard",
        "SENTRY_AUTH_TOKEN": "your_sentry_auth_token",
        "SENTRY_URL": "https://lekman-consulting.sentry.io/"
      }
    }
  }
}
```

**Important**: 
- Never commit `.mcp.json` to git (it's in `.gitignore`)
- Replace all `your_*` placeholders with actual values
- Store sensitive tokens securely

### 3. Sentry Project Details

For MagSafe Guard Sentry project:

- **Organization**: lekman-consulting
- **Project**: magsafeguard (ID: 4509752042127440)
- **User ID**: 3869449 (personal)
- **Issues URL**: https://lekman-consulting.sentry.io/issues/
- **Security Header Endpoint**: https://o4509752039243776.ingest.de.sentry.io/api/4509752042127440/security/?sentry_key=e74a158126b00e128ebdda98f6a36b76

## Task Master AI Integration

### 1. Installation

Task Master AI is automatically available via the MCP configuration above. No additional installation required.

### 2. Available Commands

Through the MCP integration, you have access to:

- `initialize_project` - Initialize Task Master in current project
- `parse_prd` - Generate tasks from PRD document  
- `get_tasks` - List all tasks with status
- `next_task` - Get next available task
- `set_task_status` - Mark tasks complete
- `add_task` - Create new tasks
- `expand_task` - Break tasks into subtasks

### 3. Local CLI Usage

You can also use Task Master directly:

```bash
# Install globally (optional)
npm install -g task-master-ai

# Initialize in project
task-master init

# Parse PRD to generate tasks
task-master parse-prd .taskmaster/docs/prd.txt

# Daily workflow
task-master next
task-master show <id>
task-master set-status --id=<id> --status=done
```

## Testing Sentry Integration

### 1. Verify Configuration

Run in Swift code:
```swift
// Initialize logging (done automatically at app start)
Log.initialize()

// Send a test event
Log.sendTestEvent { success in
    print("Test event sent: \(success)")
}
```

### 2. Check Sentry Dashboard

1. Go to https://lekman-consulting.sentry.io/issues/
2. Look for test events with tags:
   - `test_event: true`
   - `integration: sentry`
   - `component: magsafe_guard`

## Troubleshooting

### MCP Connection Issues

1. **Check Node.js**: Ensure Node.js is installed
2. **Verify tokens**: Check that API keys are valid
3. **Debug mode**: Start Claude Code with `--mcp-debug`
4. **Fallback**: Use CLI commands if MCP unavailable

### Sentry Issues

1. **Check environment**: Verify `SENTRY_ENABLED=true`
2. **Test DSN**: Validate the DSN format
3. **Network**: Ensure connectivity to sentry.io
4. **Logs**: Check console for Sentry initialization messages

### Test Event Not Appearing

1. **Check environment**: Verify Sentry is enabled
2. **Wait time**: Events may take 1-2 minutes to appear
3. **Filters**: Check Sentry filters aren't hiding test events
4. **Debug mode**: Enable `SENTRY_DEBUG=true` for more logging

## Security Considerations

- **Environment Variables**: Keep `.env` out of version control
- **MCP Config**: Never commit `.mcp.json` with real tokens
- **Production**: Disable Sentry debug mode in production
- **Feature Flags**: Use feature flags to control Sentry in different environments

## Related Documentation

- [Sentry Integration Documentation](https://docs.sentry.io/platforms/cocoa/)
- [MCP Server Documentation](https://docs.anthropic.com/en/docs/build-with-claude/mcp)
- [Task Master AI Documentation](https://github.com/TaskMasterAI/task-master-ai)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

## Support

For issues with:
- **Sentry**: Check the Sentry documentation or project issues
- **Task Master**: Use the Task Master AI GitHub repository
- **MCP**: Refer to Anthropic MCP documentation
- **Project-specific issues**: Create an issue in this repository