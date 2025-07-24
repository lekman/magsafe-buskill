#!/usr/bin/env swift

import Foundation
import IOKit.ps
import AppKit

// MARK: - Power Monitor Core

class PowerMonitorCore {
    typealias PowerStateHandler = (PowerState) -> Void
    
    struct PowerState {
        let isConnected: Bool
        let batteryLevel: Int
        let isCharging: Bool
        let adapterType: String
        let timestamp: Date
    }
    
    private var runLoopSource: CFRunLoopSource?
    private var lastState: PowerState?
    private var stateChangeHandler: PowerStateHandler?
    
    func startMonitoring(handler: @escaping PowerStateHandler) {
        self.stateChangeHandler = handler
        
        // Get initial state
        if let state = getCurrentPowerState() {
            lastState = state
            handler(state)
        }
        
        // Set up notifications
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        runLoopSource = IOPSNotificationCreateRunLoopSource(
            { context in
                let monitor = Unmanaged<PowerMonitorCore>.fromOpaque(context!).takeUnretainedValue()
                monitor.handlePowerChange()
            },
            context
        ).takeRetainedValue()
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
    }
    
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
    }
    
    private func handlePowerChange() {
        guard let newState = getCurrentPowerState() else { return }
        
        // Only notify on actual state changes
        if lastState?.isConnected != newState.isConnected {
            stateChangeHandler?(newState)
        }
        
        lastState = newState
    }
    
    private func getCurrentPowerState() -> PowerState? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let powerSourceState = info[kIOPSPowerSourceStateKey as String] as? String ?? ""
                let isConnected = (powerSourceState == kIOPSACPowerValue as String)
                
                let currentCapacity = info[kIOPSCurrentCapacityKey as String] as? Int ?? 0
                let maxCapacity = info[kIOPSMaxCapacityKey as String] as? Int ?? 1
                let batteryLevel = (currentCapacity * 100) / maxCapacity
                
                let isCharging = info[kIOPSIsChargingKey as String] as? Bool ?? false
                let adapterType = detectAdapterType(from: info)
                
                return PowerState(
                    isConnected: isConnected,
                    batteryLevel: batteryLevel,
                    isCharging: isCharging,
                    adapterType: adapterType,
                    timestamp: Date()
                )
            }
        }
        
        return nil
    }
    
    private func detectAdapterType(from info: [String: Any]) -> String {
        // Try to determine adapter type from available information
        if let adapterDetails = info["Adapter Details"] as? [String: Any] {
            if let watts = adapterDetails["Watts"] as? Int {
                switch watts {
                case 140: return "MagSafe 3 (140W)"
                case 96: return "USB-C (96W)"
                case 87: return "USB-C (87W)"
                case 67: return "MagSafe 3 (67W)"
                case 61: return "USB-C (61W)"
                case 30: return "USB-C (30W)"
                default: return "Power Adapter (\(watts)W)"
                }
            }
        }
        
        // Check if it's likely MagSafe based on Mac model
        if let model = info["Model"] as? String {
            if model.contains("MacBook") && model.contains("Pro") {
                return "MagSafe/USB-C"
            }
        }
        
        return "Power Adapter"
    }
}

// MARK: - Demo Security Actions

class SecurityActionDemo {
    enum Action: String, CaseIterable {
        case screenLock = "Lock Screen"
        case alarm = "Sound Alarm"
        case shutdown = "Shutdown"
        case custom = "Custom Script"
        
        var emoji: String {
            switch self {
            case .screenLock: return "🔒"
            case .alarm: return "🚨"
            case .shutdown: return "⚠️"
            case .custom: return "📜"
            }
        }
    }
    
    static func execute(_ action: Action, demoMode: Bool = true) {
        let prefix = demoMode ? "[DEMO] Would execute:" : "Executing:"
        
        switch action {
        case .screenLock:
            print("\n\(prefix) Lock Screen")
            if !demoMode {
                // In real app: CGSession -suspend
                let task = Process()
                task.launchPath = "/usr/bin/pmset"
                task.arguments = ["displaysleepnow"]
                task.launch()
            }
            
        case .alarm:
            print("\n\(prefix) Sound Alarm")
            if !demoMode {
                NSSound.beep()
                // In real app: Play loud alarm sound
            }
            
        case .shutdown:
            print("\n\(prefix) System Shutdown")
            if !demoMode {
                // In real app: sudo shutdown -h now
                // Requires authorization
            }
            
        case .custom:
            print("\n\(prefix) Custom Script")
            print("  ~/Library/MagSafeGuard/trigger.sh")
        }
    }
}

// MARK: - Interactive Demo

class InteractiveDemo {
    private let monitor = PowerMonitorCore()
    private var isArmed = false
    private var selectedAction = SecurityActionDemo.Action.screenLock
    
    func run() {
        printHeader()
        
        monitor.startMonitoring { [weak self] state in
            self?.handlePowerStateChange(state)
        }
        
        // Setup keyboard input
        FileHandle.standardInput.readabilityHandler = { [weak self] handle in
            let input = String(data: handle.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self?.handleCommand(input)
        }
        
        RunLoop.current.run()
    }
    
    private func printHeader() {
        print("""
        
        ⚡ MagSafe Security Guard - Proof of Concept
        ============================================
        
        This demo monitors your power adapter connection and simulates
        security actions when the adapter is disconnected while armed.
        
        Commands:
          [a] - Arm/Disarm toggle
          [1] - Select Lock Screen action
          [2] - Select Alarm action
          [3] - Select Shutdown action
          [4] - Select Custom Script action
          [s] - Show current status
          [q] - Quit
        
        """)
    }
    
    private func handlePowerStateChange(_ state: PowerMonitorCore.PowerState) {
        print("\n⚡ Power Event Detected:")
        print("  Time: \(formatTime(state.timestamp))")
        print("  Status: \(state.isConnected ? "Connected ✅" : "Disconnected ❌")")
        print("  Adapter: \(state.adapterType)")
        print("  Battery: \(state.batteryLevel)% \(state.isCharging ? "⚡" : "")")
        
        if !state.isConnected && isArmed {
            print("\n🚨 SECURITY TRIGGER!")
            print("  Armed state + Power disconnection detected")
            SecurityActionDemo.execute(selectedAction, demoMode: true)
        }
        
        print("\nCurrent Mode: \(isArmed ? "🔒 ARMED" : "🔓 DISARMED")")
        print("Selected Action: \(selectedAction.emoji) \(selectedAction.rawValue)")
        print("\n> ", terminator: "")
        fflush(stdout)
    }
    
    private func handleCommand(_ command: String) {
        switch command.lowercased() {
        case "a":
            isArmed.toggle()
            print("\nSystem is now: \(isArmed ? "🔒 ARMED" : "🔓 DISARMED")")
            
        case "1", "2", "3", "4":
            if let index = Int(command), index >= 1 && index <= SecurityActionDemo.Action.allCases.count {
                selectedAction = SecurityActionDemo.Action.allCases[index - 1]
                print("\nSelected action: \(selectedAction.emoji) \(selectedAction.rawValue)")
            }
            
        case "s":
            printStatus()
            
        case "q":
            print("\nShutting down...")
            monitor.stopMonitoring()
            exit(0)
            
        default:
            print("\nUnknown command. Use [a], [1-4], [s], or [q]")
        }
        
        print("\n> ", terminator: "")
        fflush(stdout)
    }
    
    private func printStatus() {
        print("\n📊 Current Status:")
        print("  Armed: \(isArmed ? "Yes 🔒" : "No 🔓")")
        print("  Action: \(selectedAction.emoji) \(selectedAction.rawValue)")
        print("  Monitor: Active ✅")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// Run the demo
let demo = InteractiveDemo()
demo.run()