# Settings and Persistence Guide

This guide covers the implementation of user settings and persistence in MagSafe Guard.

## Overview

The settings system provides a comprehensive UI for configuring application behavior with automatic persistence using UserDefaults. The implementation follows SwiftUI best practices and includes validation, import/export functionality, and migration support.

## Architecture

### Core Components

1. **SettingsModel.swift** - Data models and validation
   - `Settings` struct: Main settings container
   - `SecurityActionType` enum: Security action configurations
   - Validation logic for all settings

2. **UserDefaultsManager.swift** - Persistence layer
   - Singleton pattern for global access
   - Automatic saving with debouncing
   - Import/export functionality
   - Settings migration support

3. **SettingsView.swift** - SwiftUI interface
   - Tabbed interface with 5 sections
   - Real-time validation
   - Keyboard navigation support

## Settings Categories

### General Settings
- **Grace Period Duration**: 5-30 seconds slider
- **Allow Grace Period Cancellation**: Toggle for authentication during grace period
- **Launch at Login**: Auto-start application
- **Show in Dock**: Display dock icon (vs menu bar only)

### Security Settings
- **Security Actions**: Ordered list of actions to execute
  - Lock Screen
  - Log Out
  - Shut Down
  - Unmount External Volumes
  - Clear Clipboard
  - Run Custom Script
- Drag-and-drop reordering
- Add/remove actions dynamically

### Auto-Arm Settings
- **Enable Auto-Arm**: Master toggle
- **Location-Based**: Arm when leaving trusted locations
- **Network-Based**: Arm on untrusted Wi-Fi networks
- **Trusted Networks**: List of safe Wi-Fi SSIDs

### Notification Settings
- **Show Status Changes**: Notifications for arm/disarm
- **Play Alert Sound**: Critical alert sounds
- Link to system notification preferences

### Advanced Settings
- **Custom Scripts**: Shell scripts for security actions
- **Debug Logging**: Verbose logging for troubleshooting
- **Import/Export**: Settings backup and restore
- **Reset to Defaults**: Factory reset option

## Implementation Details

### Settings Validation

All settings are validated before saving:

```swift
public func validated() -> Settings {
    var validated = self
    
    // Ensure grace period is within bounds
    validated.gracePeriodDuration = max(5.0, min(30.0, gracePeriodDuration))
    
    // Ensure at least one security action
    if validated.securityActions.isEmpty {
        validated.securityActions = [.lockScreen]
    }
    
    // Remove duplicate actions
    // ... deduplication logic
    
    return validated
}
```

### Persistence Strategy

Settings are automatically persisted using UserDefaults with JSON encoding:

```swift
private func saveSettings() {
    do {
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: Keys.settings)
        userDefaults.set(currentSettingsVersion, forKey: Keys.settingsVersion)
    } catch {
        print("[UserDefaultsManager] Failed to save settings: \(error)")
    }
}
```

### Auto-Save Mechanism

Changes are debounced and auto-saved after 500ms:

```swift
$settings
    .dropFirst()
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .sink { [weak self] _ in
        self?.saveSettings()
    }
    .store(in: &cancellables)
```

### Migration Support

Future-proof migration system for settings upgrades:

```swift
private static func migrateSettings(_ settings: Settings, from version: Int) -> Settings {
    // Version-specific migrations
    switch version {
    case 0:
        // Migrate from v0 to v1
        // ... migration logic
    default:
        break
    }
    return settings
}
```

## UI/UX Considerations

### TabView Navigation
- Clear section organization
- Keyboard shortcuts for tab switching
- Visual indicators for active sections

### Form Validation
- Real-time validation feedback
- Disabled states for dependent settings
- Helpful descriptions for each option

### Accessibility
- Full VoiceOver support
- Keyboard navigation
- High contrast mode compatibility
- Clear labeling and descriptions

## Integration Points

### AppController Integration

AppController uses settings via computed properties:

```swift
public var gracePeriodDuration: TimeInterval {
    get { settingsManager.settings.gracePeriodDuration }
    set { settingsManager.updateSetting(\.gracePeriodDuration, value: newValue) }
}
```

### NotificationService Integration

Respects user notification preferences:

```swift
if !UserDefaultsManager.shared.settings.showStatusNotifications {
    print("[NotificationService] Status notifications disabled")
    return
}
```

### Settings Window Management

Proper window lifecycle handling:

```swift
let delegate = WindowDelegate { [weak self] in
    self?.settingsWindow = nil
    // Cleanup delegate reference
}
settingsWindow?.delegate = delegate
windowDelegates[settingsWindow!] = delegate  // Retain delegate
```

## Testing

### Unit Tests
- **SettingsModelTests**: Model validation and encoding
- **UserDefaultsManagerTests**: Persistence and migration
- Coverage for all validation rules
- Import/export functionality

### Integration Tests
- Settings window presentation
- Tab navigation
- Form submission and validation
- Persistence across app launches

## Best Practices

1. **Always validate settings** before persistence
2. **Use computed properties** for frequently accessed settings
3. **Implement proper error handling** for import/export
4. **Test migration paths** when adding new settings
5. **Document all settings** with clear descriptions
6. **Respect system preferences** (e.g., notification permissions)

## Future Enhancements

- Cloud sync via iCloud
- Settings profiles
- Keyboard shortcut customization
- Theme preferences
- Export to configuration file formats (plist, JSON)
- Command-line configuration support