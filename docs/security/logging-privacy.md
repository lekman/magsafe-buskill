# Logging Privacy and Security

## Overview

MagSafe Guard implements privacy-aware logging using Apple's os.log framework with appropriate privacy markers to prevent sensitive information from being logged in clear text.

## Privacy Implementation

### 1. Sensitive Data Categories

The following data is considered sensitive and logged with `.private` privacy markers:

- **Network Information**: Wi-Fi SSIDs, network connection status
- **Location Data**: Region identifiers, location authorization status
- **User Settings**: Security preferences, auto-arm configuration
- **Authentication**: Authentication reasons, biometric status
- **System State**: Detailed system status that could reveal usage patterns

### 2. Logging Methods

We provide separate methods for logging sensitive vs non-sensitive data:

```swift
// Public data - logged in clear text
Log.info("Application started", category: .general)

// Sensitive data - automatically redacted
Log.infoSensitive("Connected to network", value: ssid, category: .network)
```

### 3. Privacy Markers

All sensitive data is marked with `.private` which means:

- In production logs, the data is replaced with `<private>`
- Only users with debugging profiles can see the actual values
- Prevents accidental exposure of sensitive information

### 4. File Logging

Error logs written to disk only contain:

- Timestamp
- Log level (ERROR, CRITICAL, FAULT)
- Category
- Message text (with sensitive data already redacted)

### 5. Compliance

This approach addresses security concerns by:

- Preventing clear text logging of sensitive data (Snyk CWE-532)
- Following Apple's privacy guidelines for os.log
- Maintaining useful debugging capability while protecting user privacy
- Ensuring logs can be safely collected for troubleshooting

## Examples

### Before (Security Risk)

```swift
Log.info("Connected to network: \(ssid)", category: .network)
// Logs: "Connected to network: HomeWiFi"
```

### After (Privacy-Safe)

```swift
Log.infoSensitive("Connected to network", value: ssid, category: .network)
// Logs: "Connected to network: <private>"
```

## Developer Guidelines

1. Use standard logging methods for non-sensitive data
2. Use `*Sensitive` variants for any data that could identify:
   - User location or patterns
   - Network connections
   - Security settings
   - Authentication attempts
3. When in doubt, use the sensitive variant
4. Never log passwords, tokens, or keys (even with privacy markers)

## Testing

To verify privacy markers are working:

```bash
# View logs with privacy enabled (default)
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard"'

# View logs with privacy disabled (requires debug profile)
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard"' --debug
```
