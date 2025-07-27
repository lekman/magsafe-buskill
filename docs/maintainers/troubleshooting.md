# Troubleshooting Guide

## Common Issues and Solutions

### Bundle Identifier Errors

**Error**: "Cannot index window tabs due to missing main bundle identifier"
**Error**: "bundleProxyForCurrentProcess is nil"

**Cause**: Running from Xcode without a proper app bundle structure.

**Solutions**:

#### Option 1: Run as Bundled App (Recommended)

```bash
task run
```

This builds and launches the app with proper bundle structure.

#### Option 2: Use Xcode Product Menu

1. Build the app (⌘B)
2. Product → Show Build Folder in Finder
3. Navigate to Products/Debug/
4. Double-click MagSafeGuard.app

#### Option 3: Archive and Run

1. Product → Archive
2. Distribute App → Copy App
3. Run the exported app

### Notification Permission Issues

**Problem**: Notifications not showing

**Solutions**:

1. Check System Settings → Notifications → MagSafe Guard
2. Ensure notifications are allowed
3. The app shows alert dialogs as fallback when bundle ID is missing

### Menu Bar Icon Not Visible

**Problem**: Can't find the lock shield icon

**Solutions**:

1. Look carefully in the menu bar (top-right of screen)
2. Try clicking where you expect it
3. Check Console.app for errors
4. Ensure no crash on launch

### Power Detection Not Working

**Problem**: App doesn't detect power changes

**Solutions**:

1. Open demo window to test
2. Check Console for "[PowerMonitorService]" messages
3. Verify IOKit permissions (usually automatic)
4. Try both notification and polling modes

### High CPU Usage

**Problem**: App using too much CPU

**Solutions**:

1. Check if polling mode is active
2. Look for crash loops in Console
3. Restart the app
4. File an issue with CPU usage details

### App Crashes on Launch

**Debug Steps**:

1. Run from Xcode to see crash details
2. Check Console.app for crash logs
3. Delete derived data:

   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/MagSafeGuard-*
   ```

4. Clean build folder (⌘⇧K)

### Build Failures

**Common Fixes**:

1. Update Xcode to latest version
2. Check Swift version compatibility
3. Reset package caches:

   ```bash
   rm -rf .build
   rm Package.resolved
   swift package reset
   ```

### Demo Window Issues

**Problem**: Demo window won't open

**Solutions**:

1. Check for JavaScript errors in console
2. Ensure SwiftUI is properly imported
3. Try closing and reopening
4. Check for multiple window instances

## Debug Mode

To enable verbose logging:

1. **In Code**: Set debug flags

   ```swift
   let DEBUG_MODE = true
   ```

2. **Console Output**: Filter by process

   ```bash
   log stream --process MagSafeGuard
   ```

3. **Activity Monitor**: Check resource usage

## Logging and Diagnostics

### Understanding macOS Logging

MagSafe Guard uses Apple's native logging frameworks. Here's how to access and understand the logs:

#### 1. **os.log (Unified Logging System)** - Recommended

The modern logging system stores logs in a centralized database:

- **Storage Location**: `/var/db/diagnostics/` and `/var/db/uuidtext/` (binary format)
- **Retention**: 3-7 days (system-managed)

##### Accessing Logs via Console.app (Easiest)

1. Open `/Applications/Utilities/Console.app`
2. Select your Mac in the sidebar
3. Use these filters:
   - Subsystem: `com.magsafeguard` or `com.lekman.MagSafeGuard`
   - Process: `MagSafeGuard`
   - Category: `PowerMonitor`, `Authentication`, `Settings`, etc.

##### Accessing Logs via Terminal

```bash
# Stream live logs from MagSafe Guard
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard"'

# Stream with debug level
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard"' --level debug

# Show logs from last hour
log show --predicate 'subsystem == "com.lekman.MagSafeGuard"' --last 1h

# Show logs with all levels
log show --predicate 'subsystem == "com.lekman.MagSafeGuard"' --info --debug --last 1h

# Export logs to file
log show --predicate 'subsystem == "com.lekman.MagSafeGuard"' --last 1d > magsafe-logs.txt

# Filter by category
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND category == "PowerMonitor"'

# Search for specific text
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND eventMessage CONTAINS "power"'
```

#### 2. **print() Statements** (Development Only)

- **Location**: Only visible in Xcode's debug console
- **Not persisted** in system logs
- **Access**: Only during Xcode debugging sessions

#### 3. **Custom Log Files**

If the app writes custom logs:

- **Location**: `~/Library/Logs/MagSafeGuard/`
- **Access**: Open in any text editor

### Log Levels and Their Meanings

| Level | Usage | Visibility |
|-------|-------|------------|
| `.debug` | Detailed debugging info | Only with debug flag |
| `.info` | General information | Always visible |
| `.notice` | Normal but significant | Default level |
| `.error` | Errors needing attention | Always visible |
| `.fault` | Critical failures | Always visible |

### Common Log Patterns to Look For

#### Power Monitoring Issues

```bash
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND category == "PowerMonitor"'
```

Look for:

- "Power source changed"
- "Battery level"
- "AC Power connected/disconnected"

#### Authentication Problems

```bash
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND category == "Authentication"'
```

Look for:

- "Authentication failed"
- "TouchID not available"
- "User cancelled"

#### Settings Issues

```bash
log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND category == "Settings"'
```

Look for:

- "Failed to save settings"
- "Settings migration"
- "Invalid configuration"

### Enabling Verbose Logging

1. **For Current Session**:

   ```bash
   # Set environment variable before running
   MAGSAFE_DEBUG=1 /Applications/MagSafeGuard.app/Contents/MacOS/MagSafeGuard
   ```

2. **In Settings**: Enable "Debug Logging" in Advanced tab

3. **For Development**: Build with DEBUG flag

### Privacy in Logs

The app uses privacy markers for sensitive data:

- User locations are marked as `.private`
- Network names may be redacted
- No passwords or authentication tokens are logged

### Troubleshooting with Logs

1. **App Won't Start**:

   ```bash
   log show --predicate 'process == "MagSafeGuard"' --last 5m --info
   ```

2. **Feature Not Working**:

   ```bash
   # Replace FEATURE with PowerMonitor, AutoArm, etc.
   log stream --predicate 'subsystem == "com.lekman.MagSafeGuard" AND category == "FEATURE"'
   ```

3. **Crash Analysis**:
   - Check `~/Library/Logs/DiagnosticReports/` for crash reports
   - Look for `MagSafeGuard*.crash` files

### Exporting Logs for Bug Reports

When filing an issue, include:

```bash
# Create a diagnostic bundle
mkdir ~/Desktop/magsafe-diagnostics
cd ~/Desktop/magsafe-diagnostics

# Export recent logs
log show --predicate 'subsystem == "com.lekman.MagSafeGuard"' --last 1h > system-logs.txt

# Copy crash reports if any
cp ~/Library/Logs/DiagnosticReports/MagSafeGuard*.crash . 2>/dev/null

# System info
system_profiler SPSoftwareDataType SPHardwareDataType > system-info.txt

# Create archive
cd ..
zip -r magsafe-diagnostics.zip magsafe-diagnostics/
```

## Getting Help

If issues persist:

1. **Collect Information**:
   - macOS version
   - Xcode version
   - Error messages
   - Console logs

2. **File an Issue**:
   - GitHub Issues page
   - Include reproduction steps
   - Attach relevant logs

3. **Temporary Workarounds**:
   - Use alert dialogs instead of notifications
   - Run the pre-built release version
   - Disable problematic features temporarily
