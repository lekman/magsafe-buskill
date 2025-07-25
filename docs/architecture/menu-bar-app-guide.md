# Menu Bar Application Guide

## Overview

MagSafe Guard runs as a menu bar application on macOS, providing quick access to security controls without cluttering the dock or requiring a full window interface.

## Menu Bar Integration

### Status Item Setup

```swift
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
```

**Key Components**:

- `NSStatusItem`: Represents the menu bar presence
- `NSStatusBar.system`: System-wide menu bar
- Variable length allows icon to size naturally

### Icon Management

**Icon States**:

- **Disarmed**: `lock.shield` (outline icon)
- **Armed**: `lock.shield.fill` (filled icon, red tint)

**Implementation**:

```swift
private func updateStatusIcon() {
    if let button = statusItem?.button {
        let iconName = isArmed ? "lock.shield.fill" : "lock.shield"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MagSafe Guard")
        
        if isArmed {
            button.contentTintColor = .systemRed
        } else {
            button.contentTintColor = nil
        }
    }
}
```

## Menu Structure

### Current Menu Layout

```
┌─────────────────────────┐
│ Armed/Disarmed          │ (Status indicator)
├─────────────────────────┤
│ Arm/Disarm             │ (Toggle action)
├─────────────────────────┤
│ Power Connected         │ (Power status)
│ Battery: 85%           │ (Battery info)
├─────────────────────────┤
│ Settings...            │ (Future: preferences)
│ Show Demo...           │ (Demo window)
├─────────────────────────┤
│ Quit MagSafe Guard     │ (Exit app)
└─────────────────────────┘
```

### Menu Construction

```swift
private func setupMenu() {
    let menu = NSMenu()
    
    // Status indicator (disabled)
    let statusMenuItem = NSMenuItem(title: isArmed ? "Armed" : "Disarmed", action: nil, keyEquivalent: "")
    statusMenuItem.isEnabled = false
    menu.addItem(statusMenuItem)
    
    // Actions
    menu.addItem(NSMenuItem(title: isArmed ? "Disarm" : "Arm", action: #selector(toggleArmed), keyEquivalent: "a"))
    
    // ... additional items
    
    statusItem?.menu = menu
}
```

## App Lifecycle

### Hiding Dock Icon

```swift
NSApp.setActivationPolicy(.accessory)
```

**Effect**: App runs without dock icon, only in menu bar.

### Launch Behavior

1. App launches
2. Dock icon briefly appears
3. `applicationDidFinishLaunching` called
4. Dock icon hidden
5. Menu bar icon appears
6. Power monitoring starts

## User Interactions

### Armed/Disarmed Toggle

**Keyboard Shortcut**: ⌘A (when menu open)

**Behavior**:

1. Toggle internal state
2. Update icon appearance
3. Rebuild menu
4. Show notification
5. Start/stop security monitoring

### Demo Window

**Keyboard Shortcut**: ⌘D (when menu open)

**Implementation**:

```swift
@objc private func showDemo() {
    if demoWindow == nil {
        let demoView = PowerMonitorDemoView()
        
        demoWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        demoWindow?.title = "Power Monitor Demo"
        demoWindow?.contentView = NSHostingView(rootView: demoView)
        demoWindow?.center()
    }
    
    demoWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}
```

## Notifications

### System Notifications

**Current Implementation** (Deprecated API):

```swift
let notification = NSUserNotification()
notification.title = title
notification.informativeText = message
notification.soundName = NSUserNotificationDefaultSoundName
NSUserNotificationCenter.default.deliver(notification)
```

**Notification Scenarios**:

- Armed/Disarmed state changes
- Security alerts when triggered
- Connection errors

### Future Migration

Need to migrate to `UNUserNotificationCenter`:

```swift
import UserNotifications

let content = UNMutableNotificationContent()
content.title = title
content.body = message
content.sound = .default

let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
UNUserNotificationCenter.current().add(request)
```

## Security Actions

### Current Implementation

**Screen Lock**:

```swift
let task = Process()
task.launchPath = "/usr/bin/pmset"
task.arguments = ["displaysleepnow"]
task.launch()
```

**Trigger Conditions**:

1. App is armed
2. Power disconnected detected
3. No grace period (immediate action)

### Future Enhancements

Planned security actions:

- System logout
- Sleep mode
- Custom scripts
- Alarm sounds
- Network disconnection

## Best Practices

### Menu Updates

1. **Batch Updates**: Rebuild entire menu rather than individual items
2. **Main Thread**: Always update UI on main thread
3. **Responsive**: Keep menu actions fast (< 100ms)

### State Management

```swift
private var isArmed = false {
    didSet {
        updateStatusIcon()
        setupMenu()
    }
}
```

### Memory Management

- Window lazy loading
- Proper cleanup in `applicationWillTerminate`
- Weak references in closures

## Debugging

### Console Output

Run from Xcode to see debug prints:

```
[AppDelegate] Power state: Power adapter connected
[PowerMonitorService] Started monitoring (mode: notifications)
⚠️ SECURITY ALERT: Power disconnected while armed!
```

### Common Issues

1. **Menu Not Appearing**:
   - Check `statusItem` creation
   - Verify button has image
   - Ensure menu assignment

2. **Icon Not Changing**:
   - Verify `updateStatusIcon` called
   - Check tint color support
   - Test with different icons

3. **Actions Not Firing**:
   - Verify `@objc` on methods
   - Check selector syntax
   - Ensure menu item has action

## Testing Menu Bar Apps

### Manual Testing

1. **Build and Run**: ⌘R in Xcode
2. **Find Icon**: Look in top-right menu bar
3. **Test States**: Click to open menu
4. **Keyboard**: Test shortcuts with menu open

### Automated Testing

Menu bar apps are challenging to unit test. Focus on:

- Model/state testing
- Service layer testing
- Manual UI verification

### Accessibility

Ensure menu items have:

- Clear titles
- Keyboard shortcuts where appropriate
- Proper enabled/disabled states
- Accessibility descriptions for icons
