# MagSafe Guard User Guide

This guide covers all features and functionality of MagSafe Guard.

## Table of Contents

- [Overview](#overview)
- [Basic Usage](#basic-usage)
- [Security Actions](#security-actions)
- [Grace Period](#grace-period)
- [Auto-Arm Features](#auto-arm-features)
- [Evidence Collection](#evidence-collection)
- [iCloud Sync](#icloud-sync)
- [Trusted Networks](#trusted-networks)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Best Practices](#best-practices)

## Overview

MagSafe Guard protects your Mac from theft by monitoring power adapter disconnection. When armed and your power adapter is unplugged, it can automatically lock your screen, shutdown, or run custom security actions.

## Basic Usage

### Menu Bar Interface

The shield icon in your menu bar shows the current status:

- 🛡️ **Gray Shield**: Disarmed (inactive)
- 🛡️ **Blue Shield**: Armed (monitoring)
- ⚠️ **Yellow Shield**: Grace period active
- ❌ **Red Shield**: Security action triggered

### Arming and Disarming

**To Arm Protection**:

1. Click the menu bar icon
2. Select "Arm Protection"
3. The shield turns blue

**To Disarm Protection**:

1. Click the menu bar icon
2. Select "Disarm Protection"
3. Authenticate with Touch ID or password
4. The shield turns gray

## Security Actions

Configure what happens when power is disconnected while armed:

### Lock Screen (Default)

- Immediately locks your Mac
- Requires password/Touch ID to unlock
- Recommended for most users

### Shutdown

- Forces immediate system shutdown
- More secure but may lose unsaved work
- Good for high-security environments

### Sleep

- Puts Mac to sleep
- Faster recovery than shutdown
- Still requires authentication to wake

### Custom Script

- Run your own security script
- Examples:
  - Send alert to phone
  - Wipe sensitive data
  - Trigger alarm sound

To configure:

1. Open Settings → Security
2. Choose your preferred action
3. For custom script, provide full path

## Grace Period

The grace period gives you time to reconnect power before the security action executes.

### Setting Grace Period

1. Open Settings → Security
2. Adjust slider (0-60 seconds)
3. 0 seconds = immediate action

### During Grace Period

- Alert window appears with countdown
- Loud alert sound (optional)
- Reconnect power to cancel
- Or authenticate to cancel

### Best Settings

- **Public spaces**: 0-5 seconds
- **Office**: 10-20 seconds  
- **Home**: 30-60 seconds

## Auto-Arm Features

MagSafe Guard can automatically arm itself based on conditions:

### Location-Based Auto-Arm

1. Enable in Settings → Auto-Arm
2. Set "Trusted Locations"
3. Auto-arms when leaving trusted areas

### Network-Based Auto-Arm

1. Enable in Settings → Auto-Arm
2. Mark current network as "Trusted"
3. Auto-arms on untrusted networks

### Time-Based Auto-Arm

1. Set schedule in Settings → Auto-Arm
2. Example: Arm at 9 AM, disarm at 5 PM
3. Useful for work hours

### Smart Detection

- Combines multiple conditions
- Example: Arm when both:
  - Not at home/office location
  - Not on trusted Wi-Fi

## Evidence Collection

When enabled, captures evidence during security events:

### What's Collected

- **Photo**: Front camera snapshot
- **Location**: Current GPS coordinates
- **Timestamp**: Exact time of event
- **Device Info**: Mac details

### Privacy Settings

1. Enable in Settings → Security
2. Choose what to collect
3. All evidence is encrypted
4. Only accessible with your password

### Viewing Evidence

1. Open Settings → Evidence Log
2. Click event to view details
3. Export for law enforcement if needed

## iCloud Sync

Sync settings and evidence across your Macs:

### Enabling iCloud Sync

1. Sign in to iCloud on Mac
2. Enable in Settings → iCloud
3. Choose sync options

### What Syncs

- All settings and preferences
- Trusted locations/networks
- Security evidence (encrypted)
- Event history

### Privacy

- End-to-end encrypted
- Apple cannot access your data
- Optional - works without iCloud

## Trusted Networks

Configure Wi-Fi networks where auto-arm should not activate:

### Adding Trusted Networks

1. Connect to Wi-Fi network
2. Open Settings → Networks
3. Click "Trust Current Network"

### Managing Networks

- View all trusted networks
- Remove outdated entries
- Set expiration dates
- Name networks for clarity

## Keyboard Shortcuts

Quick actions without clicking menu:

- **⌘⌥L**: Lock now (bypass arm state)
- **⌘⌥A**: Toggle arm/disarm
- **⌘⌥S**: Open settings
- **⌘⌥E**: View event log

Enable in Settings → Shortcuts

## Best Practices

### Daily Use

1. **Arm when arriving** at coffee shops, libraries
2. **Use Auto-Arm** for convenience
3. **Test monthly** to ensure it works
4. **Keep grace period short** in public

### Security Tips

- Don't share your disarm method
- Use strong Mac password
- Enable FileVault encryption
- Review event logs regularly

### Battery Considerations

- MagSafe Guard uses minimal battery
- Location services increase usage
- Disable unused features to save power

### Travel Tips

1. **Airport Security**: Disarm before checkpoints
2. **Hotel Rooms**: Use 0-second grace period
3. **Conferences**: Enable evidence collection
4. **International**: Check local laws on surveillance apps

## Troubleshooting Quick Fixes

### Not Detecting Power Disconnect

- Check Settings → Power Monitoring
- Restart MagSafe Guard
- Try different power adapter

### False Triggers

- Increase grace period
- Check power adapter connection
- Update macOS

### Can't Disarm

- Force quit from Activity Monitor
- Boot in Safe Mode
- Reset permissions

For more help, see [Troubleshooting Guide](troubleshooting.md)

## Advanced Features

### Automation Integration

- Works with Shortcuts app
- Trigger with automation
- Combine with other security apps

### Multi-User Support

- Each user has own settings
- Admin can set policies
- Guest users auto-armed

### Companion iOS App

- Remote arm/disarm
- View Mac location
- Receive theft alerts
- (Coming soon)

## Privacy & Security

MagSafe Guard is designed with privacy first:

- **Local Processing**: Everything runs on your Mac
- **No Analytics**: We don't collect usage data  
- **Open Source**: Audit the code yourself
- **Minimal Permissions**: Only what's necessary

## Getting More Help

- **User Forum**: Share tips with other users
- **Video Tutorials**: Visual guides on YouTube
- **Email Support**: support@magsafeguard.app
- **GitHub**: Report bugs and request features
