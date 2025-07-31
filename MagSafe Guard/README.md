# MagSafe Guard Xcode Project

This is the Xcode project structure for MagSafe Guard, migrated from Swift Package Manager to resolve CloudKit and app launch issues.

## Project Structure

```
MagSafe Guard/
├── Controllers/
│   └── AppController.swift         # Main app controller
├── Services/                       # Core services
│   ├── AuthenticationService.swift
│   ├── PowerMonitorService.swift
│   ├── SecurityActionsService.swift
│   ├── SyncService.swift          # CloudKit sync
│   └── ...
├── Views/
│   ├── Settings/                  # Settings UI
│   │   ├── SettingsView.swift
│   │   ├── CloudSyncSettingsView.swift
│   │   └── ...
│   └── PowerMonitorDemoView.swift
├── Models/
│   └── SettingsModel.swift
├── Utilities/
│   ├── Logger.swift
│   ├── FeatureFlags.swift
│   └── AccessibilityExtensions.swift
├── AppDelegate.swift              # Main app delegate
├── MagSafe_GuardApp.swift        # App entry point
├── Assets.xcassets               # App icons and images
├── Info.plist                    # App configuration
└── MagSafe_Guard.entitlements    # App entitlements
```

## Building in Xcode

1. Open `MagSafe Guard.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Ensure CloudKit capability is enabled
4. Build and run (⌘R)

## CloudKit Configuration

The app uses CloudKit for syncing settings across devices. The container identifier is configured in the entitlements file as `iCloud.com.lekman.magsafeguard`.

## Key Features

- Menu bar app with power monitoring
- CloudKit sync for settings
- Location-based auto-arming
- Security actions on cable disconnect
- Touch ID/password authentication