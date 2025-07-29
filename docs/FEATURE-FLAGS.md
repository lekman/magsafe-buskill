# Feature Flags Documentation

## Overview

MagSafe Guard uses a feature flag system to control which features are enabled. This allows for:
- Progressive feature rollout
- Easy debugging by disabling specific features
- Different configurations for development/production
- Quick feature toggling without code changes

## Configuration

Feature flags are configured through a JSON file: `feature-flags.json`

### Setup

1. Copy the example configuration:
   ```bash
   cp feature-flags.example.json feature-flags.json
   ```

2. Edit `feature-flags.json` to enable/disable features as needed

3. The app will automatically load the configuration on startup

### File Locations

The feature flag system searches for `feature-flags.json` in these locations (in order):
1. Current working directory
2. Application bundle resources
3. User's home directory
4. Application Support directory

### Priority

Configuration is loaded in this order (highest priority first):
1. Environment variables (e.g., `FEATURE_POWER_MONITORING=false`)
2. JSON configuration file
3. Default values (all enabled)

## Available Flags

### Core Features

| Flag | Default | Description |
|------|---------|-------------|
| `FEATURE_POWER_MONITORING` | `true` | Power adapter monitoring (core functionality) |
| `FEATURE_ACCESSIBILITY` | `true` | Accessibility permissions for system actions |
| `FEATURE_NOTIFICATIONS` | `true` | System notifications |
| `FEATURE_AUTHENTICATION` | `true` | Touch ID/password authentication |
| `FEATURE_AUTO_ARM` | `true` | Automatic arming based on conditions |

### Optional Features

| Flag | Default | Description |
|------|---------|-------------|
| `FEATURE_LOCATION` | `true` | Location-based features |
| `FEATURE_NETWORK_MONITOR` | `true` | Network-based auto-arm |
| `FEATURE_SECURITY_EVIDENCE` | `true` | Security evidence collection |
| `FEATURE_CLOUD_SYNC` | `true` | iCloud sync functionality |

### Telemetry

| Flag | Default | Description |
|------|---------|-------------|
| `SENTRY_ENABLED` | `true` | Sentry crash reporting and telemetry |
| `SENTRY_DEBUG` | `true` | Sentry debug mode |
| `FEATURE_PERFORMANCE_METRICS` | `true` | Performance metrics tracking |

### Debug Options

| Flag | Default | Description |
|------|---------|-------------|
| `DEBUG_VERBOSE_LOGGING` | `true` | Verbose debug logging |
| `DEBUG_MOCK_SERVICES` | `false` | Use mock services for testing |
| `DEBUG_DISABLE_SANDBOX` | `false` | Disable app sandbox (development only) |

## Usage in Code

### Checking Feature Flags

```swift
// Check single flag
if FeatureFlags.shared.isEnabled(.powerMonitoring) {
    // Power monitoring code
}

// Convenience properties
if FeatureFlags.shared.isPowerMonitoringEnabled {
    // Power monitoring code
}

// Check multiple flags (all must be enabled)
if FeatureFlags.shared.areEnabled(.location, .networkMonitor) {
    // Code requiring both features
}

// Check if any flag is enabled
if FeatureFlags.shared.isAnyEnabled(.location, .networkMonitor) {
    // Code requiring either feature
}
```

### Setting Flags Programmatically (Testing)

```swift
// Set flag for testing
FeatureFlags.shared.setFlag(.mockServices, enabled: true)

// Reload configuration from disk
FeatureFlags.shared.reload()

// Save current configuration
try FeatureFlags.shared.saveToJSON()
```

## Example Configurations

### Production (Recommended)

```json
{
  "FEATURE_POWER_MONITORING": true,
  "FEATURE_ACCESSIBILITY": true,
  "FEATURE_NOTIFICATIONS": true,
  "FEATURE_AUTHENTICATION": true,
  "FEATURE_AUTO_ARM": true,
  "FEATURE_LOCATION": true,
  "FEATURE_NETWORK_MONITOR": true,
  "FEATURE_SECURITY_EVIDENCE": false,
  "FEATURE_CLOUD_SYNC": false,
  "SENTRY_ENABLED": false,
  "SENTRY_DEBUG": false,
  "FEATURE_PERFORMANCE_METRICS": false,
  "DEBUG_VERBOSE_LOGGING": false,
  "DEBUG_MOCK_SERVICES": false,
  "DEBUG_DISABLE_SANDBOX": false
}
```

### Development

```json
{
  "FEATURE_POWER_MONITORING": true,
  "FEATURE_ACCESSIBILITY": true,
  "FEATURE_NOTIFICATIONS": true,
  "FEATURE_AUTHENTICATION": true,
  "FEATURE_AUTO_ARM": true,
  "FEATURE_LOCATION": true,
  "FEATURE_NETWORK_MONITOR": true,
  "FEATURE_SECURITY_EVIDENCE": true,
  "FEATURE_CLOUD_SYNC": true,
  "SENTRY_ENABLED": false,
  "SENTRY_DEBUG": false,
  "FEATURE_PERFORMANCE_METRICS": true,
  "DEBUG_VERBOSE_LOGGING": true,
  "DEBUG_MOCK_SERVICES": false,
  "DEBUG_DISABLE_SANDBOX": false
}
```

### Minimal (Core Only)

```json
{
  "FEATURE_POWER_MONITORING": true,
  "FEATURE_ACCESSIBILITY": true,
  "FEATURE_NOTIFICATIONS": true,
  "FEATURE_AUTHENTICATION": true,
  "FEATURE_AUTO_ARM": false,
  "FEATURE_LOCATION": false,
  "FEATURE_NETWORK_MONITOR": false,
  "FEATURE_SECURITY_EVIDENCE": false,
  "FEATURE_CLOUD_SYNC": false,
  "SENTRY_ENABLED": false,
  "SENTRY_DEBUG": false,
  "FEATURE_PERFORMANCE_METRICS": false,
  "DEBUG_VERBOSE_LOGGING": false,
  "DEBUG_MOCK_SERVICES": false,
  "DEBUG_DISABLE_SANDBOX": false
}
```

## Troubleshooting

### Flags Not Loading

1. Check file exists in one of the search locations
2. Verify JSON syntax is valid
3. Check console logs for loading errors
4. Try setting via environment variable to test

### Performance Impact

- Feature flag checks are very fast (synchronized dictionary lookup)
- Configuration is loaded once at startup
- Use `reload()` to refresh configuration without restart

### Security Considerations

- Never commit `feature-flags.json` with production settings
- Use environment variables for sensitive flags in CI/CD
- Some flags (like `DEBUG_DISABLE_SANDBOX`) should never be enabled in production