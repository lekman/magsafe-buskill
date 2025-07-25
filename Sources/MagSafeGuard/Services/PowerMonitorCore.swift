//
//  PowerMonitorCore.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This file contains the testable core logic extracted from PowerMonitorService
//  to enable better unit testing without IOKit dependencies.
//

import Foundation

/// Core logic for power monitoring that can be tested without IOKit dependencies
public class PowerMonitorCore {
    
    // MARK: - Types
    
    /// Power state information
    public struct PowerInfo: Equatable {
        public let state: PowerState
        public let batteryLevel: Int?
        public let isCharging: Bool
        public let adapterWattage: Int?
        public let timestamp: Date
        
        public init(state: PowerState, batteryLevel: Int?, isCharging: Bool, adapterWattage: Int?, timestamp: Date) {
            self.state = state
            self.batteryLevel = batteryLevel
            self.isCharging = isCharging
            self.adapterWattage = adapterWattage
            self.timestamp = timestamp
        }
    }
    
    /// Power connection state
    public enum PowerState: String, Equatable {
        case connected = "connected"
        case disconnected = "disconnected"
        
        public var description: String {
            switch self {
            case .connected:
                return "Power adapter connected"
            case .disconnected:
                return "Power adapter disconnected"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Current power information
    public private(set) var currentPowerInfo: PowerInfo?
    
    /// Polling interval in seconds
    public let pollingInterval: TimeInterval
    
    // MARK: - Initialization
    
    public init(pollingInterval: TimeInterval = 1.0) {
        self.pollingInterval = pollingInterval
    }
    
    // MARK: - Public Methods
    
    /// Process power source information from IOKit
    /// - Parameter powerSourceInfo: Dictionary from IOPSCopyPowerSourcesInfo
    /// - Returns: PowerInfo if successfully parsed
    public func processPowerSourceInfo(_ sources: [[String: Any]]) -> PowerInfo? {
        var state: PowerState = .disconnected
        var batteryLevel: Int?
        var isCharging = false
        var adapterWattage: Int?
        
        for sourceDict in sources {
            // Check power state
            if let powerSourceState = sourceDict["Power Source State"] as? String {
                state = (powerSourceState == "AC Power") ? .connected : .disconnected
            }
            
            // Get battery level
            if let currentCapacity = sourceDict["Current Capacity"] as? Int,
               let maxCapacity = sourceDict["Max Capacity"] as? Int,
               maxCapacity > 0 {
                batteryLevel = Int((Double(currentCapacity) / Double(maxCapacity)) * 100)
            }
            
            // Check if charging
            if let chargingFlag = sourceDict["Is Charging"] as? Bool {
                isCharging = chargingFlag
            }
            
            // Get adapter wattage if available
            if let adapterInfo = sourceDict["AdapterInfo"] as? Int {
                adapterWattage = adapterInfo
            } else if let adapterDetails = sourceDict["AdapterDetails"] as? [String: Any],
                      let watts = adapterDetails["Watts"] as? Int {
                adapterWattage = watts
            }
        }
        
        return PowerInfo(
            state: state,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            adapterWattage: adapterWattage,
            timestamp: Date()
        )
    }
    
    /// Determine if power state has changed
    /// - Parameter newInfo: New power information
    /// - Returns: True if state changed, false otherwise
    public func hasPowerStateChanged(newInfo: PowerInfo) -> Bool {
        guard let currentInfo = currentPowerInfo else {
            // First reading
            currentPowerInfo = newInfo
            return true
        }
        
        if currentInfo.state != newInfo.state {
            currentPowerInfo = newInfo
            return true
        }
        
        // Update current info even if state didn't change
        currentPowerInfo = newInfo
        return false
    }
    
    /// Create Objective-C compatible battery level
    /// - Returns: Battery level (0-100) or -1 if unavailable
    @objc public func getBatteryLevel() -> Int {
        return currentPowerInfo?.batteryLevel ?? -1
    }
    
    /// Create Objective-C compatible power connection status
    /// - Returns: True if power is connected
    @objc public func isPowerConnected() -> Bool {
        return currentPowerInfo?.state == .connected
    }
    
    /// Reset current power info (for testing)
    public func reset() {
        currentPowerInfo = nil
    }
}

// MARK: - IOKit Constants (for reference)

import IOKit.ps

// These constants are defined in IOKit.ps and used as CFString
// We'll use the string values directly in our code since they're CFString constants