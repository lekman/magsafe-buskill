#!/usr/bin/env swift

import Foundation
import IOKit.ps

class PowerMonitor {
    private var powerSource: CFTypeRef?
    private var runLoopSource: CFRunLoopSource?
    private var isMonitoring = false
    private var lastPowerState: Bool?
    
    init() {
        print("PowerMonitor initialized")
    }
    
    func startMonitoring() {
        print("\n🔌 Power Monitor POC Started")
        print("================================")
        print("Monitoring power adapter connection...")
        print("Press Ctrl+C to exit\n")
        
        // Get initial power state
        updatePowerState()
        
        // Create the run loop source for power source notifications
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        runLoopSource = IOPSNotificationCreateRunLoopSource(
            powerSourceCallback,
            context
        ).takeRetainedValue()
        
        // Add to run loop
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            runLoopSource,
            .defaultMode
        )
        
        isMonitoring = true
        
        // Keep the program running
        CFRunLoopRun()
    }
    
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetCurrent(),
                source,
                .defaultMode
            )
        }
        isMonitoring = false
        print("\nMonitoring stopped")
    }
    
    private func updatePowerState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        var isACPowered = false
        var batteryLevel: Int?
        var isCharging = false
        
        for source in sources {
            if let sourceDict = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                // Debug: Print all available keys
                if lastPowerState == nil {
                    print("Available power source keys:")
                    sourceDict.keys.sorted().forEach { print("  - \($0)") }
                    print("")
                }
                
                // Check if we're on AC power
                if let powerSourceState = sourceDict[kIOPSPowerSourceStateKey as String] as? String {
                    isACPowered = (powerSourceState == kIOPSACPowerValue as String)
                }
                
                // Get battery level
                if let currentCapacity = sourceDict[kIOPSCurrentCapacityKey as String] as? Int,
                   let maxCapacity = sourceDict[kIOPSMaxCapacityKey as String] as? Int {
                    batteryLevel = (currentCapacity * 100) / maxCapacity
                }
                
                // Check if charging
                if let chargingValue = sourceDict[kIOPSIsChargingKey as String] as? Bool {
                    isCharging = chargingValue
                }
                
                // Additional useful information
                let powerType = sourceDict[kIOPSTypeKey as String] as? String ?? "Unknown"
                let name = sourceDict[kIOPSNameKey as String] as? String ?? "Unknown"
                
                // Only print on state change or first run
                if lastPowerState == nil || lastPowerState != isACPowered {
                    print("\n⚡ Power State Changed!")
                    print("  Timestamp: \(Date())")
                    print("  AC Power: \(isACPowered ? "Connected ✅" : "Disconnected ❌")")
                    print("  Battery Level: \(batteryLevel ?? 0)%")
                    print("  Charging: \(isCharging ? "Yes" : "No")")
                    print("  Power Source: \(name) (\(powerType))")
                    
                    if lastPowerState != nil && !isACPowered {
                        print("\n🚨 ALERT: Power adapter disconnected!")
                        print("  This would trigger security action in armed state")
                    }
                    
                    lastPowerState = isACPowered
                }
            }
        }
    }
    
    // Callback function for power state changes
    private let powerSourceCallback: IOPowerSourceCallbackType = { context in
        let monitor = Unmanaged<PowerMonitor>.fromOpaque(context!).takeUnretainedValue()
        monitor.updatePowerState()
    }
}

// Create and run the monitor
let monitor = PowerMonitor()

// Handle Ctrl+C gracefully
signal(SIGINT) { _ in
    print("\n\nShutting down...")
    exit(0)
}

monitor.startMonitoring()