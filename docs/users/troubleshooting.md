# MagSafe Guard Troubleshooting Guide

This guide helps you solve common issues with MagSafe Guard.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Startup Problems](#startup-problems)
- [Power Detection Issues](#power-detection-issues)
- [Permission Problems](#permission-problems)
- [False Triggers](#false-triggers)
- [Performance Issues](#performance-issues)
- [iCloud Sync Issues](#icloud-sync-issues)
- [Getting More Help](#getting-more-help)

## Installation Issues

### "MagSafe Guard is damaged and can't be opened"

This happens when macOS quarantines downloaded apps.

**Solution**:
```bash
# Remove quarantine flag
xattr -cr /Applications/MagSafeGuard.app

# Or from Terminal:
sudo spctl --master-disable  # Temporarily allow apps from anywhere
# Install MagSafe Guard
sudo spctl --master-enable   # Re-enable Gatekeeper
```

### "MagSafe Guard cannot be opened because the developer cannot be verified"

**Solution**:
1. Don't double-click to open
2. Right-click the app → Select "Open"
3. Click "Open" in the warning dialog
4. This adds a security exception

### App doesn't appear in Applications folder after dragging

**Solution**:
1. Check if it's still in Downloads
2. Try copying instead of moving
3. Ensure you have write permissions to /Applications

## Startup Problems

### Menu bar icon doesn't appear

**Possible Causes & Solutions**:

1. **App crashed on startup**
   - Open Activity Monitor
   - Search for "MagSafeGuard"
   - If found, quit it and restart
   
2. **Hidden menu bar**
   - Move mouse to top of screen
   - Check if menu bar is set to auto-hide
   
3. **Too many menu bar items**
   - Hold ⌘ and drag other icons to remove
   - Make space for MagSafe Guard

4. **macOS bug**
   - Log out and log back in
   - Or restart your Mac

### App crashes immediately after launching

**Solutions**:
1. Delete preferences:
   ```bash
   defaults delete com.lekman.MagSafeGuard
   ```

2. Check Console for errors:
   - Open Console.app
   - Search for "MagSafeGuard"
   - Look for crash reports

3. Reinstall the app:
   - Delete from Applications
   - Empty Trash
   - Download fresh copy

### "Background Items Added" notification

This is normal - MagSafe Guard needs to run in background.

**To verify**:
1. System Settings → General → Login Items
2. Ensure MagSafe Guard is allowed
3. If missing, add it manually

## Power Detection Issues

### Not detecting power adapter disconnection

**Check these**:

1. **Power adapter type**
   - Works with MagSafe and USB-C
   - May not work with third-party adapters
   
2. **Power monitoring enabled**
   - Settings → Power Monitoring
   - Toggle off and on
   
3. **System permissions**
   - System Settings → Privacy & Security
   - Ensure Accessibility is granted

4. **Test with different adapter**
   - Try another Apple adapter
   - Test different power outlet

### Detecting disconnection when adapter is connected

**Common causes**:

1. **Loose connection**
   - Check adapter connection
   - Clean MagSafe/USB-C port
   - Check for debris

2. **Faulty adapter**
   - Test with another adapter
   - Check adapter LED (if applicable)

3. **Power fluctuations**
   - Try different outlet
   - Use surge protector

## Permission Problems

### "MagSafe Guard would like to access..." dialogs

Required permissions and why:

1. **Accessibility** (Required)
   - Needed to lock screen and execute security actions
   - Without it, app cannot function

2. **Camera** (Optional)
   - Only for evidence collection
   - Can work without it

3. **Location Services** (Optional)
   - For auto-arm features
   - Can work without it

4. **Notifications** (Recommended)
   - For security alerts
   - Important for grace period warnings

### Permissions not working after granting

**Fix steps**:
1. System Settings → Privacy & Security
2. Find the relevant permission
3. Toggle MagSafe Guard OFF
4. Quit MagSafe Guard
5. Toggle permission back ON
6. Restart MagSafe Guard

### Cannot grant Accessibility permission

**If toggle is grayed out**:
1. Check if managed by organization
2. Try in Safe Mode
3. Reset permissions:
   ```bash
   tccutil reset Accessibility com.lekman.MagSafeGuard
   ```

## False Triggers

### Security action triggers randomly

**Common causes & fixes**:

1. **Loose power connection**
   - Check cable and port
   - Replace if worn

2. **Power management issues**
   - Reset SMC (System Management Controller)
   - Update macOS

3. **Increase grace period**
   - Settings → Security
   - Set 10-30 seconds minimum

### Triggers when Mac sleeps/wakes

**Solution**:
- Settings → Advanced
- Enable "Ignore during sleep"
- Or increase grace period

## Performance Issues

### High CPU usage

**Check these**:
1. Activity Monitor → CPU
2. If >5% constantly:
   - Disable unused features
   - Check for updates
   - Reinstall app

### Battery drains quickly

**Power-saving tips**:
1. Disable location services if not using auto-arm
2. Reduce evidence collection frequency
3. Turn off iCloud sync if not needed

### Mac runs slowly when armed

This is unusual. Try:
1. Update to latest version
2. Reset preferences
3. Contact support with diagnostics

## iCloud Sync Issues

### Settings not syncing between Macs

**Troubleshooting steps**:

1. **Verify iCloud signed in**
   - System Settings → Apple ID
   - Same account on all Macs

2. **Check iCloud Drive enabled**
   - Must be on for sync
   
3. **Force sync**
   - Settings → iCloud → Sync Now
   
4. **Reset sync**
   - Turn off iCloud sync
   - Wait 1 minute
   - Turn back on

### "iCloud not available" message

**Possible fixes**:
1. Check internet connection
2. Sign out and back into iCloud
3. Check Apple System Status
4. Wait and try later

### Evidence not uploading

**Check**:
1. Storage limit in Settings
2. Available iCloud storage
3. Internet connection speed
4. File size limits

## Getting More Help

### Diagnostic Information

When contacting support, provide:

1. **System info**:
   ```bash
   sw_vers  # macOS version
   sysctl hw.model  # Mac model
   ```

2. **App version**:
   - MagSafe Guard menu → About

3. **Console logs**:
   - Console.app → Search "MagSafeGuard"
   - Copy relevant entries

4. **Crash reports**:
   - Console → Crash Reports
   - Look for MagSafeGuard

### Reset Everything

If all else fails:

1. Quit MagSafe Guard
2. Delete app from Applications
3. Remove all settings:
   ```bash
   defaults delete com.lekman.MagSafeGuard
   rm -rf ~/Library/Application\ Support/MagSafeGuard
   ```
4. Empty Trash
5. Restart Mac
6. Reinstall fresh

### Contact Support

- **GitHub Issues**: [Report bugs](https://github.com/lekman/magsafe-buskill/issues)
- **Email**: support@magsafeguard.app
- **Response time**: 24-48 hours

### Emergency Disarm

If locked out and need to disarm:

1. **Force quit**:
   - ⌘⌥⎋ (Cmd+Option+Esc)
   - Select MagSafe Guard
   - Force Quit

2. **Safe Mode**:
   - Restart holding Shift
   - MagSafe Guard won't load
   - Fix issues then restart normally

3. **Terminal** (if you can access):
   ```bash
   killall MagSafeGuard
   ```

## Known Issues

### macOS Ventura (13.x)
- First launch may require two attempts
- Location permission dialog may not appear

### macOS Sonoma (14.x)
- Menu bar icon may disappear after sleep
- Fix: Click where icon should be

### Apple Silicon Macs
- Power detection more sensitive
- Adjust thresholds in Advanced settings

### Intel Macs
- Slightly higher CPU usage normal
- Evidence collection may be slower

Check [GitHub Issues](https://github.com/lekman/magsafe-buskill/issues) for latest known issues and fixes.