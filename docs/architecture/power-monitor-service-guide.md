# PowerMonitorService Technical Guide

## Overview

The PowerMonitorService is the core component responsible for detecting power adapter connection changes on macOS. It uses the IOKit framework to monitor power sources and provides a callback-based notification system.

## API Reference

### PowerState Enum

```swift
public enum PowerState: String {
    case connected = "connected"
    case disconnected = "disconnected"
}
```

**Purpose**: Represents the current power connection state.

### PowerInfo Struct

```swift
public struct PowerInfo {
    let state: PowerState
    let batteryLevel: Int?
    let isCharging: Bool
    let adapterWattage: Int?
    let timestamp: Date
}
```

**Fields**:

- `state`: Current power connection state
- `batteryLevel`: Battery percentage (0-100), nil if unavailable
- `isCharging`: Whether battery is currently charging
- `adapterWattage`: Power adapter wattage (may be nil)
- `timestamp`: When this info was captured

### Public Methods

#### startMonitoring(callback:)

```swift
public func startMonitoring(callback: @escaping PowerStateCallback)
```

**Purpose**: Start monitoring power state changes.

**Parameters**:

- `callback`: Closure called when power state changes

**Behavior**:

- Immediately calls callback with current state
- Sets up IOKit notifications or polling
- Thread-safe, can be called multiple times

**Example**:

```swift
PowerMonitorService.shared.startMonitoring { powerInfo in
    print("Power state: \(powerInfo.state)")
    print("Battery: \(powerInfo.batteryLevel ?? -1)%")
}
```

#### stopMonitoring()

```swift
public func stopMonitoring()
```

**Purpose**: Stop monitoring power state changes.

**Behavior**:

- Removes IOKit notifications
- Stops polling timer
- Clears callbacks
- Thread-safe

#### getCurrentPowerInfo()

```swift
public func getCurrentPowerInfo() -> PowerInfo?
```

**Purpose**: Get current power information synchronously.

**Returns**: Current power info or nil if unavailable.

**Use Case**: One-time power state check without continuous monitoring.

## IOKit Integration

### How It Works

1. **Power Source Info Retrieval**:

   ```swift
   let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
   let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue()
   ```

2. **Power State Detection**:
   - Checks `kIOPSPowerSourceStateKey` for AC power status
   - Value of `kIOPSACPowerValue` indicates connected
   - Any other value indicates disconnected

3. **Notification System**:

   ```swift
   IOPSNotificationCreateRunLoopSource(callback, context)
   ```

   - Registers callback for power source changes
   - More efficient than polling
   - Automatic fallback to polling if registration fails

### IOKit Keys Used

| Key | Purpose | Type |
|-----|---------|------|
| `kIOPSPowerSourceStateKey` | Power source state | String |
| `kIOPSACPowerValue` | AC power indicator | String constant |
| `kIOPSCurrentCapacityKey` | Current battery capacity | Int |
| `kIOPSMaxCapacityKey` | Maximum battery capacity | Int |
| `kIOPSIsChargingKey` | Charging status | Bool |

## Implementation Details

### Notification Mode

**Advantages**:

- Minimal CPU usage (< 0.1%)
- Instant detection (< 100ms)
- System-level integration

**How it works**:

1. Creates run loop source with `IOPSNotificationCreateRunLoopSource`
2. Adds source to main run loop
3. Callback invoked on power state changes
4. Validates state change before notifying observers

### Polling Mode (Fallback)

**When used**:

- IOKit notification registration fails
- Testing/debugging scenarios

**Characteristics**:

- 100ms polling interval (as per PRD)
- Timer on main run loop
- Still maintains low CPU usage

### Thread Safety

**Queue Design**:

```swift
private let queue = DispatchQueue(label: "com.magsafeguard.powermonitor", qos: .utility)
```

**Synchronization**:

- All state mutations on serial queue
- Callbacks dispatched to main thread
- No locks required due to serial queue

## Usage Examples

### Basic Monitoring

```swift
// Start monitoring
PowerMonitorService.shared.startMonitoring { powerInfo in
    if powerInfo.state == .disconnected {
        print("Power disconnected!")
    }
}

// Stop when done
PowerMonitorService.shared.stopMonitoring()
```

### Armed Security Mode

```swift
var isArmed = false

PowerMonitorService.shared.startMonitoring { powerInfo in
    if isArmed && powerInfo.state == .disconnected {
        triggerSecurityAction()
    }
}
```

### Battery Monitoring

```swift
PowerMonitorService.shared.startMonitoring { powerInfo in
    guard let battery = powerInfo.batteryLevel else { return }
    
    if battery < 20 && !powerInfo.isCharging {
        showLowBatteryWarning()
    }
}
```

## Testing

### Unit Testing

The service includes comprehensive unit tests:

- Singleton behavior
- State transitions
- Callback invocations
- Thread safety
- Objective-C compatibility

### Manual Testing

1. **Power Detection Test**:
   - Start monitoring
   - Unplug power adapter
   - Verify disconnected state
   - Plug in power adapter
   - Verify connected state

2. **Performance Test**:
   - Monitor CPU usage in Activity Monitor
   - Should remain under 1% during active monitoring

3. **Reliability Test**:
   - Rapid plug/unplug cycles
   - Sleep/wake cycles
   - Multiple observers

## Troubleshooting

### Common Issues

1. **No Power State Changes Detected**
   - Check Console.app for IOKit errors
   - Verify app has necessary permissions
   - Test with demo app first

2. **High CPU Usage**
   - Ensure notification mode is active
   - Check for callback loops
   - Verify timer cleanup on stop

3. **Incorrect Battery Level**
   - Some Macs report battery differently
   - Check for multiple power sources
   - Validate capacity calculations

### Debug Logging

Enable verbose logging:

```swift
// In PowerMonitorService
print("[PowerMonitorService] Started monitoring (mode: \(self.useNotifications ? "notifications" : "polling"))")
```

Check Console.app for output filtering by "PowerMonitorService".

## Best Practices

1. **Always Stop Monitoring**:

   ```swift
   deinit {
       PowerMonitorService.shared.stopMonitoring()
   }
   ```

2. **Handle nil Values**:

   ```swift
   let battery = powerInfo.batteryLevel ?? 0
   ```

3. **Debounce Rapid Changes**:
   - IOKit may report multiple events
   - Implement debouncing if needed

4. **Test on Multiple Macs**:
   - Intel vs Apple Silicon
   - Desktop vs Laptop
   - Different macOS versions
