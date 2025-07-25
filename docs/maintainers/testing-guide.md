# Testing Guide for MagSafe Guard

## Overview

This guide covers testing strategies, procedures, and best practices for MagSafe Guard, including unit tests, integration tests, and manual testing scenarios.

## Unit Testing

### Test Structure

```ini
Tests/
└── MagSafeGuardTests/
    ├── MagSafeGuardTests.swift      # Basic app tests
    └── PowerMonitorServiceTests.swift # Service tests
```

### Running Unit Tests

**From Xcode**:

- Press `⌘U` (Command+U)
- Or select Product → Test

**From Terminal**:

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test class
swift test --filter PowerMonitorServiceTests

# Run specific test method
swift test --filter PowerMonitorServiceTests.testStartMonitoring
```

### Current Test Coverage

#### PowerMonitorServiceTests

| Test                          | Purpose                    | Status |
| ----------------------------- | -------------------------- | ------ |
| `testServiceSingleton`        | Verify singleton pattern   | ✅     |
| `testInitialState`            | Check default values       | ✅     |
| `testStartMonitoring`         | Validate monitoring starts | ✅     |
| `testStopMonitoring`          | Ensure cleanup works       | ✅     |
| `testGetCurrentPowerInfo`     | Test sync power check      | ✅     |
| `testObjectiveCCompatibility` | ObjC bridge testing        | ✅     |
| `testPowerStateEnum`          | Enum values/descriptions   | ✅     |

### Writing New Tests

#### Basic Test Template

```swift
func testNewFeature() {
    // Arrange
    let service = PowerMonitorService.shared
    let expectation = XCTestExpectation(description: "Callback fired")

    // Act
    service.startMonitoring { powerInfo in
        // Assert
        XCTAssertNotNil(powerInfo)
        expectation.fulfill()
    }

    // Wait
    wait(for: [expectation], timeout: 1.0)
}
```

#### Testing Async Operations

```swift
func testAsyncPowerChange() {
    let expectation = XCTestExpectation(description: "Power state changed")
    var callCount = 0

    service.startMonitoring { _ in
        callCount += 1
        if callCount > 1 {
            expectation.fulfill()
        }
    }

    // Simulate power change
    // Note: Actual power changes require manual testing

    wait(for: [expectation], timeout: 5.0)
}
```

## Integration Testing

### Power Detection Testing

**Test Scenarios**:

1. **Normal Operation**:

   - Plug in power → Verify "connected" state
   - Unplug power → Verify "disconnected" state
   - Multiple cycles → Ensure consistency

2. **Edge Cases**:

   - Rapid plug/unplug cycles
   - Sleep/wake with power changes
   - Multiple power adapters (if available)

3. **Performance**:
   - CPU usage under 1%
   - Memory stable over time
   - No memory leaks

### Menu Bar Integration

**Manual Test Steps**:

1. **Launch Test**:

   ```text
   ✓ App launches without crash
   ✓ No dock icon appears
   ✓ Menu bar icon visible
   ```

2. **Menu Test**:

   ```text
   ✓ Click opens menu
   ✓ All items visible
   ✓ Keyboard shortcuts work
   ✓ Items enable/disable correctly
   ```

3. **State Management**:

   ```text
   ✓ Armed state persists
   ✓ Icon updates on state change
   ✓ Menu reflects current state
   ```

## Manual Testing Procedures

### Basic Functionality Test

1. **Setup**:

   - Build and run app
   - Open demo window
   - Have power adapter ready

2. **Power Detection**:

   - Start monitoring in demo
   - Unplug power adapter
   - Verify: Icon red, state "disconnected"
   - Plug in power adapter
   - Verify: Icon green, state "connected"

3. **Security Features**:
   - Disarm the app (default state)
   - Unplug power → Nothing happens
   - Arm the app (icon turns red)
   - Unplug power → Screen locks

### Stress Testing

#### Rapid State Changes

```bash
# Pseudo-script for manual testing
1. Start monitoring
2. For 30 seconds:
   - Unplug adapter
   - Wait 1 second
   - Plug adapter
   - Wait 1 second
3. Check:
   - No crashes
   - All changes detected
   - UI responsive
```

#### Long-Duration Test

1. Start app in armed mode
2. Leave running for 24 hours
3. Monitor:
   - CPU usage (Activity Monitor)
   - Memory usage
   - Battery impact
4. Verify still responsive

### Platform Testing

#### macOS Versions

Test on:

- macOS 13 (Ventura) - Minimum
- macOS 14 (Sonoma) - Current
- macOS 15 (Beta) - Future

#### Hardware Variants

- **MacBook Air**: USB-C power
- **MacBook Pro**: USB-C/MagSafe 3
- **Mac mini**: Different power architecture
- **Intel Mac**: Legacy hardware
- **Apple Silicon**: Current hardware

## Performance Testing

### Using Instruments

1. **Launch Instruments**:

   ```bash
   open /Applications/Xcode.app/Contents/Applications/Instruments.app
   ```

2. **Select Templates**:

   - Time Profiler: CPU usage
   - Allocations: Memory usage
   - Energy Log: Battery impact

3. **Key Metrics**:
   - CPU: < 1% when idle
   - Memory: < 50MB total
   - Wake ups: Minimal

### Command Line Monitoring

```bash
# Monitor CPU usage
top -pid $(pgrep MagSafeGuard)

# Check memory
footprint MagSafeGuard

# System calls
dtrace -n 'syscall:::entry /execname == "MagSafeGuard"/ { @[probefunc] = count(); }'
```

## Test Automation

### UI Testing (Future)

```swift
import XCTest

class MagSafeGuardUITests: XCTestCase {
    func testMenuBarInteraction() {
        let app = XCUIApplication()
        app.launch()

        // Find menu bar item
        let menuBar = app.menuBars
        let statusItem = menuBar.statusItems["MagSafe Guard"]

        // Click to open menu
        statusItem.click()

        // Verify menu items
        XCTAssert(app.menuItems["Arm"].exists)
    }
}
```

### Continuous Integration Tests

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          swift test
          xcodebuild test -scheme MagSafeGuard
```

## Test Data and Scenarios

### Power States Test Matrix

| Scenario            | Initial State        | Action         | Expected Result    |
| ------------------- | -------------------- | -------------- | ------------------ |
| Normal connect      | Disconnected         | Plug adapter   | Connected state    |
| Normal disconnect   | Connected            | Unplug adapter | Disconnected state |
| Armed disconnect    | Armed + Connected    | Unplug         | Screen lock        |
| Disarmed disconnect | Disarmed + Connected | Unplug         | No action          |
| Sleep transition    | Connected            | Sleep Mac      | State maintained   |
| Wake transition     | Any                  | Wake Mac       | State updated      |

### Error Scenarios

1. **IOKit Failure**:

   - Simulate by denying permissions
   - Should fall back to polling
   - Log appropriate errors

2. **Memory Pressure**:

   - Run with memory constraints
   - Should handle gracefully
   - No crashes or data loss

3. **Rapid User Actions**:
   - Spam arm/disarm
   - Multiple demo windows
   - Menu during updates

## Debugging Test Failures

### Common Issues

1. **Timing Issues**:

   ```swift
   // Bad: Fixed delay
   Thread.sleep(forTimeInterval: 1.0)

   // Good: Expectation with timeout
   wait(for: [expectation], timeout: 5.0)
   ```

2. **State Isolation**:

   ```swift
   override func setUp() {
       super.setUp()
       // Reset singleton state
       PowerMonitorService.shared.stopMonitoring()
   }
   ```

3. **Main Thread**:

   ```swift
   // Ensure UI updates on main thread
   DispatchQueue.main.async {
       XCTAssertEqual(label.stringValue, "Expected")
   }
   ```

### Test Logging

Enable verbose logging for tests:

```swift
// In test setup
UserDefaults.standard.set(true, forKey: "EnableTestLogging")

// In service
if UserDefaults.standard.bool(forKey: "EnableTestLogging") {
    print("[TEST] Power state: \(state)")
}
```

## Test Reports

### Coverage Report

Generate coverage report:

```bash
# Build with coverage
xcodebuild test -scheme MagSafeGuard -enableCodeCoverage YES

# View report
xcrun xccov view --report derived_data/Logs/Test/*.xcresult
```

### Test Summary

After each release, document:

- Tests run: X total
- Pass rate: X%
- Coverage: X%
- Performance: CPU < X%, Memory < XMB
- Known issues: List any
