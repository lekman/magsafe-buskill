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
