# MagSafe Guard Installation Guide

This guide will help you install and set up MagSafe Guard on your Mac.

## System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Hardware**: Any Mac with MagSafe or USB-C power adapter
- **Permissions**: Administrator access for initial setup

## Download Options

### Option 1: Download Pre-built Release (Recommended)

1. Visit the [MagSafe Guard Releases](https://github.com/lekman/magsafe-buskill/releases) page
2. Download the latest `.dmg` file
3. Open the downloaded DMG file
4. Drag MagSafe Guard to your Applications folder

### Option 2: Build from Source

If you prefer to build from source, see the [Building and Running](../maintainers/building-and-running.md) guide.

## Installation Steps

### 1. First Launch

When you first open MagSafe Guard:

1. **macOS Security Warning**: You'll see "MagSafe Guard can't be opened because it is from an unidentified developer"
   - Right-click the app in Applications
   - Select "Open" from the context menu
   - Click "Open" in the dialog

2. **Permissions Required**: The app will request several permissions:
   - **Accessibility**: Required for system-wide security actions
   - **Camera**: Optional - for evidence collection during security events
   - **Location**: Optional - for location-based auto-arm features
   - **Notifications**: Recommended - for security alerts

### 2. Initial Setup

After granting permissions:

1. **Menu Bar Icon**: Look for the shield icon in your menu bar
2. **Click the icon** to access MagSafe Guard settings
3. **Configure Security Actions**:
   - Lock Screen (default)
   - Shutdown
   - Custom Script
4. **Set Grace Period**: Time before security action executes (0-60 seconds)

### 3. Test Your Setup

1. **Arm the System**: Click "Arm Protection" in the menu
2. **Test Safely**: 
   - Unplug your power adapter
   - You should see an alert
   - Plug it back in to cancel
3. **Verify Settings**: Check that your chosen action would have executed

## Troubleshooting Installation

### "Damaged App" Error

If macOS says the app is damaged:

```bash
# Remove quarantine attribute
xattr -cr /Applications/MagSafeGuard.app
```

### App Doesn't Appear in Menu Bar

1. Check Activity Monitor for MagSafeGuard process
2. Try launching from Applications folder again
3. Check Console.app for error messages

### Permissions Not Working

1. Open System Settings → Privacy & Security
2. Check each permission category:
   - Accessibility
   - Camera (if using evidence collection)
   - Location Services (if using auto-arm)
3. Toggle permissions off and on if needed

## Uninstallation

To remove MagSafe Guard:

1. Quit MagSafe Guard from the menu bar
2. Delete from Applications folder
3. Remove settings (optional):
   ```bash
   defaults delete com.lekman.MagSafeGuard
   ```

## Security Notes

- MagSafe Guard is signed with a Developer ID certificate
- The app runs entirely locally - no data is sent to external servers
- iCloud sync is optional and end-to-end encrypted
- Source code is available for security audit

## Next Steps

- Read the [User Guide](user-guide.md) to learn about all features
- Configure [Auto-Arm](user-guide.md#auto-arm-features) for automatic protection
- Set up [iCloud Sync](user-guide.md#icloud-sync) for multi-device support

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/lekman/magsafe-buskill/issues)
- **Security**: See our [Security Policy](../SECURITY.md)
- **Troubleshooting**: [Common Problems](troubleshooting.md)