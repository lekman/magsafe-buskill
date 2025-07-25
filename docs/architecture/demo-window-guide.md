# Demo Window Guide

## Overview

The demo window provides a graphical interface for testing and visualizing the PowerMonitorService functionality. It's built with SwiftUI and can be launched from the main app's menu bar.

## Architecture

### SwiftUI View Structure

```
PowerMonitorDemoView
├── VStack (main container)
    ├── Title
    ├── Power State Display
    │   ├── Icon (bolt/bolt.slash)
    │   └── Status Text
    ├── Battery Info Section
    │   ├── Battery Level Text
    │   ├── ProgressView
    │   └── Charging Indicator
    ├── Control Buttons
    │   ├── Start/Stop Monitoring
    │   └── Refresh
    └── Instructions
```

### View Model Pattern

**PowerMonitorDemoViewModel**:

- `@StateObject` for SwiftUI lifecycle
- `@Published` properties for UI binding
- Direct integration with PowerMonitorService

## UI Components

### Power State Display

```swift
HStack {
    Image(systemName: viewModel.isConnected ? "bolt.fill" : "bolt.slash")
        .foregroundColor(viewModel.isConnected ? .green : .red)
        .font(.system(size: 50))
    
    VStack(alignment: .leading) {
        Text("Power State: \(viewModel.powerState)")
            .font(.headline)
        Text("Last Update: \(viewModel.lastUpdate)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

**Visual Indicators**:

- Green bolt (⚡) = Connected
- Red slashed bolt = Disconnected
- Real-time color changes

### Battery Information

```swift
VStack {
    Text("Battery Level: \(batteryLevel)%")
        .font(.headline)
    
    ProgressView(value: Double(batteryLevel), total: 100)
        .progressViewStyle(.linear)
        .frame(width: 200)
    
    if viewModel.isCharging {
        Label("Charging", systemImage: "battery.100.bolt")
            .foregroundColor(.green)
    }
}
```

**Features**:

- Percentage display
- Visual progress bar
- Charging status indicator

### Control Buttons

**Start/Stop Monitoring**:

- Toggles real-time power monitoring
- Updates every callback from service
- Button label changes based on state

**Refresh**:

- One-time power state check
- Updates UI immediately
- Useful for testing without continuous monitoring

## View Model Implementation

### State Management

```swift
class PowerMonitorDemoViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var powerState = "Unknown"
    @Published var batteryLevel: Int?
    @Published var isCharging = false
    @Published var adapterWattage: Int?
    @Published var lastUpdate = "Never"
    @Published var isMonitoring = false
    
    private let powerMonitor = PowerMonitorService.shared
}
```

### Monitoring Control

```swift
func toggleMonitoring() {
    if isMonitoring {
        powerMonitor.stopMonitoring()
        isMonitoring = false
    } else {
        powerMonitor.startMonitoring { [weak self] powerInfo in
            self?.updateUI(with: powerInfo)
        }
        isMonitoring = true
    }
}
```

**Key Points**:

- Weak self to prevent retain cycles
- UI updates on main thread (handled by service)
- State tracking for button labels

### Data Formatting

```swift
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()
```

**Time Display**: Shows last update time in readable format (e.g., "2:34:56 PM")

## Window Management

### Creation and Display

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

### Window Characteristics

- **Size**: 480x600 pixels
- **Style**: Standard window with title bar
- **Resizable**: Yes
- **Centered**: On first display
- **Singleton**: Only one instance

## Testing Scenarios

### Basic Power Detection

1. Open demo window
2. Click "Start Monitoring"
3. Unplug power adapter
4. Observe:
   - Icon changes to red
   - State shows "disconnected"
   - Timestamp updates

### Battery Monitoring

1. Run on MacBook (not desktop)
2. Start monitoring
3. Observe battery percentage
4. Plug/unplug to see charging status

### Performance Testing

1. Start monitoring
2. Open Activity Monitor
3. Check MagSafe Guard CPU usage
4. Should remain < 1%

### Rapid State Changes

1. Start monitoring
2. Rapidly plug/unplug adapter
3. Verify:
   - All changes detected
   - UI remains responsive
   - No crashes or hangs

## Troubleshooting

### Common Issues

1. **Window Not Opening**:
   - Check if `demoWindow` is nil
   - Verify SwiftUI imports
   - Check for compilation errors

2. **No Updates**:
   - Ensure monitoring is started
   - Check PowerMonitorService is working
   - Verify callback registration

3. **Incorrect Values**:
   - Some Macs don't report adapter wattage
   - Battery info may be nil on desktops
   - IOKit limitations vary by model

### Debug Tips

Add logging to track issues:

```swift
func updateUI(with powerInfo: PowerMonitorService.PowerInfo) {
    print("[Demo] Updating UI with state: \(powerInfo.state)")
    // ... rest of update
}
```

## Future Enhancements

### Planned Features

1. **Historical Graph**: Show power state over time
2. **Statistics**: Connection/disconnection counts
3. **Settings Preview**: Test different configurations
4. **Export Logs**: Save monitoring data

### UI Improvements

1. **Dark Mode**: Better theme support
2. **Animations**: Smooth transitions
3. **Sound Effects**: Audio feedback option
4. **Compact Mode**: Smaller window option

## Code Organization

### File Structure

```
Views/
└── PowerMonitorDemoView.swift
    ├── PowerMonitorDemoView (SwiftUI View)
    └── PowerMonitorDemoViewModel (ObservableObject)
```

### Dependencies

- SwiftUI framework
- PowerMonitorService
- No external packages

### Build Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+
