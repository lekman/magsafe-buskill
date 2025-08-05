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

## Application Integration

### 1. Automatic Initialization

The Sentry integration is automatically initialized when the application starts through the existing `Logger` infrastructure. The `SentryLogger.initialize()` is called during app startup.

### 2. Integration with Existing Logger  

The Sentry integration works alongside the existing `Logger` system:

```swift
// Regular logging continues to work as normal
Log.info("Application started", category: .general)
Log.error("Authentication failed", category: .authentication)

// Sentry automatically captures errors and creates breadcrumbs
// No code changes needed for basic integration
```

### 3. Custom Sentry Events

For advanced use cases, call `SentryLogger` directly:

```swift
// Capture specific errors with context
SentryLogger.logError("Power adapter disconnected", category: .hardware)

// Add user context for support
SentryLogger.setUserContext(context: [
    "magsafe_connected": false,
    "power_status": "battery"
])
```

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
// Initialize Sentry (done automatically at app start)
SentryLogger.initialize()

// Send a test event to verify connectivity
SentryLogger.sendTestEvent { success in
    print("Test event sent: \(success)")
}

// Test error logging
SentryLogger.logError("Test error message", category: .security)

// Test user context
SentryLogger.setUserContext(context: ["test_run": "true"])
```

### 2. Available Logging Methods

The `SentryLogger` provides several methods:

```swift
// Error logging with optional Swift Error
SentryLogger.logError("Critical error occurred", error: someError, category: .security)

// Warning logging
SentryLogger.logWarning("Performance degradation detected", category: .performance)

// Info logging (creates breadcrumbs)
SentryLogger.logInfo("User logged in successfully", category: .authentication)

// User context (anonymous by default)
SentryLogger.setUserContext(userId: "user-123", context: ["premium": true])

// Flush pending events before app termination
SentryLogger.flush(timeout: 5.0)
```

### 3. Check Sentry Dashboard

1. Go to https://lekman-consulting.sentry.io/issues/
2. Look for test events with tags:
   - `test_event: true`
   - `integration: sentry`
   - `component: magsafe_guard`
   - `purpose: connectivity_verification`

### 4. Environment-Based Configuration

The integration automatically configures based on environment variables:

```bash
# Required
SENTRY_DSN=https://your-dsn-here
SENTRY_ENABLED=true

# Optional
SENTRY_ENVIRONMENT=development  # or staging, production
SENTRY_DEBUG=true              # Enable debug logging
```

### 5. Performance Monitoring

The integration includes automatic performance monitoring:

- **Development**: 100% transaction sampling
- **Production**: 10% transaction sampling
- Automatic release tracking via app version
- Privacy-first data scrubbing

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
5. **Feature flags**: Verify `FeatureFlags.shared.isSentryEnabled` if using feature flags

### Test Event Not Appearing

1. **Check environment**: Verify Sentry is enabled
2. **Check initialization**: Ensure `SentryLogger.initialize()` was called
3. **Wait time**: Events may take 1-2 minutes to appear
4. **Filters**: Check Sentry filters aren't hiding test events
5. **Debug mode**: Enable `SENTRY_DEBUG=true` for more logging
6. **Check status**: Use `SentryLogger.isEnabled` to verify Sentry is active

### Data Privacy Issues

The integration includes automatic data scrubbing for:

- Password fields (`password=***`)
- API tokens (`token=***`, `key=***`)
- User file paths (`/Users/***`)
- Email addresses (`***@***.***`)

To customize data scrubbing, modify the `scrubSensitiveData` method in `SentryLogger.swift`.

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
