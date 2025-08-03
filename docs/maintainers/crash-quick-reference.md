# MagSafe Guard Crash Prevention Quick Reference

## Common Crashes in This Project

### 1. Window Management Crashes

**Issue**: Force unwrapping `settingsWindow` after it's been set to nil

**Fix Applied**:

```swift
// AppController.swift
func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // Prevent app exit when closing settings
}

// Safe window handling
private weak var settingsWindow: NSWindow?
private var settingsHostingController: NSHostingController<SettingsView>?
```

### 2. CloudKit Initialization Crash

**Issue**: CloudKit initializing during app startup causing EXC_BREAKPOINT

**Fix Applied**:

```swift
// SyncService.swift
public override init() {
    super.init()
    // Defer initialization to avoid circular dependency
    syncStatus = .unknown
    isAvailable = false
}

public func enableSync() {
    guard !isCloudKitInitialized else { return }
    initializeCloudKit()
}
```

### 3. Circular Dependency Crash

**Issue**: UserDefaultsManager and SyncService creating each other recursively

**Fix Applied**:

```swift
// UserDefaultsManager.swift
init() {
    // Load settings first
    loadSettings()
    
    // Then initialize sync service
    if FeatureFlags.shared.isCloudSyncEnabled {
        self.syncService = SyncServiceFactory.create()
    }
    
    // Enable sync after initialization
    if settings.iCloudSyncEnabled, let syncService = self.syncService {
        syncService.enableSync()
    }
}
```

### 4. Missing Resources Crash

**Issue**: Bundle resources not found causing app crash

**Fix Applied**:

```swift
// Package.swift
resources: [
    .copy("../../Resources/Assets.xcassets"),
    .copy("../../Resources/Info.plist")
],
linkerSettings: [
    .linkedFramework("IOKit"),
    .linkedFramework("CloudKit"),
    // ... other frameworks
]
```

### 5. SwiftUI State Update Crash

**Issue**: Modifying @Published properties during view updates

**Fix Applied**:

```swift
// CloudSyncSettingsView.swift
.onChange(of: settingsManager.settings.iCloudSyncEnabled) { newValue in
    if newValue {
        syncService.enableSync()
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            try? await syncService.syncAll()
        }
    }
}
```

## Prevention Patterns

### Always Use Guard/If-Let

```swift
// ❌ DON'T
let window = settingsWindow!

// ✅ DO
guard let window = settingsWindow else { return }
```

### Weak References for UI Elements

```swift
// ❌ DON'T
private var settingsWindow: NSWindow?

// ✅ DO
private weak var settingsWindow: NSWindow?
```

### Defer Initialization

```swift
// ❌ DON'T
init() {
    setupEverything()  // Can cause circular dependencies
}

// ✅ DO
init() {
    // Minimal setup
}

func enableFeature() {
    // Deferred initialization
}
```

### Main Thread UI Updates

```swift
// ❌ DON'T
Task {
    statusText = "Updated"
}

// ✅ DO
Task { @MainActor in
    statusText = "Updated"
}
```

### Safe CloudKit Container

```swift
// ❌ DON'T
container = CKContainer(identifier: "specific-id")

// ✅ DO (when provisioning profile doesn't specify containers)
container = CKContainer.default()
```

## Debug Commands

```bash
# Run with crash logs
task run:debug 2>&1 | tee crash.log

# Check for force unwraps
grep -r "!" Sources/ | grep -v "!=" | grep -v "import"

# Find weak reference issues
grep -r "weak var" Sources/

# Check async main thread violations
grep -r "Task {" Sources/ | grep -B2 -A2 "self\."
```

## Crash Symbolication

When app crashes with error like `EXC_BREAKPOINT` or `EXC_BAD_ACCESS`:

1. Get crash log: `~/Library/Logs/DiagnosticReports/`
2. Find matching dSYM: `.build/debug/MagSafeGuard.dSYM`
3. Symbolicate: `atos -o MagSafeGuard.app/Contents/MacOS/MagSafeGuard -l 0x1234 0x5678`

## Emergency Fixes

### App Won't Launch

```bash
# Reset preferences
defaults delete com.lekman.magsafeguard

# Clean build
task clean && task build

# Run without signing
task run:unsigned
```

### CloudKit Crashes

```bash
# Disable CloudKit temporarily
defaults write com.lekman.magsafeguard iCloudSyncEnabled -bool NO
```

### Window Crashes

```bash
# Reset window positions
defaults delete com.lekman.magsafeguard NSWindow
```
