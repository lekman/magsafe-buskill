//
//  PowerMonitorService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import IOKit.ps

/// Service responsible for monitoring power adapter connection status
public class PowerMonitorService: NSObject {
    
    // MARK: - Types
    
    /// Represents the current power connection state
    public enum PowerState: String {
        case connected = "connected"
        case disconnected = "disconnected"
        
        var description: String {
            switch self {
            case .connected:
                return "Power adapter connected"
            case .disconnected:
                return "Power adapter disconnected"
            }
        }
    }
    
    /// Power source information
    public struct PowerInfo {
        let state: PowerState
        let batteryLevel: Int?
        let isCharging: Bool
        let adapterWattage: Int?
        let timestamp: Date
    }
    
    /// Callback type for power state changes
    public typealias PowerStateCallback = (PowerInfo) -> Void
    
    // MARK: - Properties
    
    /// Shared instance for singleton pattern
    public static let shared = PowerMonitorService()
    
    /// Current power state
    private(set) public var currentPowerInfo: PowerInfo?
    
    /// Polling interval in seconds (100ms as per PRD)
    private let pollingInterval: TimeInterval = 0.1
    
    /// Timer for polling power state
    private var pollingTimer: Timer?
    
    /// Callback for state changes
    private var stateChangeCallback: PowerStateCallback?
    
    /// Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.magsafeguard.powermonitor", qos: .utility)
    
    /// Flag to track monitoring status
    private(set) public var isMonitoring = false
    
    /// IOKit notification run loop source
    private var runLoopSource: CFRunLoopSource?
    
    /// Flag to use notification-based monitoring instead of polling
    private let useNotifications = true
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring power state changes
    /// - Parameter callback: Closure called when power state changes
    public func startMonitoring(callback: @escaping PowerStateCallback) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.isMonitoring {
                print("[PowerMonitorService] Already monitoring")
                return
            }
            
            self.stateChangeCallback = callback
            self.isMonitoring = true
            
            // Get initial state
            if let powerInfo = self.getCurrentPowerInfo() {
                self.currentPowerInfo = powerInfo
                
                DispatchQueue.main.async {
                    callback(powerInfo)
                }
            }
            
            // Use either notifications or polling
            if self.useNotifications {
                self.setupPowerNotifications()
            } else {
                // Start polling timer on main run loop
                DispatchQueue.main.async { [weak self] in
                    self?.startPollingTimer()
                }
            }
            
            print("[PowerMonitorService] Started monitoring (mode: \(self.useNotifications ? "notifications" : "polling"))")
        }
    }
    
    /// Stop monitoring power state changes
    public func stopMonitoring() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isMonitoring {
                print("[PowerMonitorService] Not currently monitoring")
                return
            }
            
            self.isMonitoring = false
            
            if self.useNotifications {
                self.removePowerNotifications()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.stopPollingTimer()
                }
            }
            
            self.stateChangeCallback = nil
            print("[PowerMonitorService] Stopped monitoring")
        }
    }
    
    /// Get current power information
    /// - Returns: Current power info or nil if unavailable
    public func getCurrentPowerInfo() -> PowerInfo? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        var state: PowerState = .disconnected
        var batteryLevel: Int?
        var isCharging = false
        var adapterWattage: Int?
        
        for source in sources {
            if let sourceDict = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                // Check power state
                if let powerSourceState = sourceDict[kIOPSPowerSourceStateKey as String] as? String {
                    state = (powerSourceState == kIOPSACPowerValue as String) ? .connected : .disconnected
                }
                
                // Get battery level
                if let currentCapacity = sourceDict[kIOPSCurrentCapacityKey as String] as? Int,
                   let maxCapacity = sourceDict[kIOPSMaxCapacityKey as String] as? Int,
                   maxCapacity > 0 {
                    batteryLevel = (currentCapacity * 100) / maxCapacity
                }
                
                // Check charging status
                if let chargingValue = sourceDict[kIOPSIsChargingKey as String] as? Bool {
                    isCharging = chargingValue
                }
                
                // Try to get adapter wattage (not always available)
                if let adapterInfo = sourceDict["AdapterDetails"] as? [String: Any],
                   let watts = adapterInfo["Watts"] as? Int {
                    adapterWattage = watts
                }
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
    
    // MARK: - Private Methods
    
    private func startPollingTimer() {
        pollingTimer = Timer.scheduledTimer(
            timeInterval: pollingInterval,
            target: self,
            selector: #selector(pollPowerState),
            userInfo: nil,
            repeats: true
        )
        
        // Ensure timer runs even during UI events
        if let timer = pollingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    @objc private func pollPowerState() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let newPowerInfo = self.getCurrentPowerInfo() {
                // Check if state changed
                if let currentInfo = self.currentPowerInfo,
                   currentInfo.state != newPowerInfo.state {
                    
                    self.currentPowerInfo = newPowerInfo
                    
                    // Notify on main thread
                    if let callback = self.stateChangeCallback {
                        DispatchQueue.main.async {
                            callback(newPowerInfo)
                        }
                    }
                    
                    print("[PowerMonitorService] Power state changed to: \(newPowerInfo.state.description)")
                } else if self.currentPowerInfo == nil {
                    self.currentPowerInfo = newPowerInfo
                }
            }
        }
    }
    
    // MARK: - IOKit Notification Methods
    
    private func setupPowerNotifications() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        runLoopSource = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context = context else { return }
                let service = Unmanaged<PowerMonitorService>.fromOpaque(context).takeUnretainedValue()
                service.powerSourceChanged()
            },
            context
        )?.takeRetainedValue()
        
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            print("[PowerMonitorService] IOKit notifications setup complete")
        } else {
            print("[PowerMonitorService] Failed to create IOKit notification source, falling back to polling")
            // Fallback to polling
            DispatchQueue.main.async { [weak self] in
                self?.startPollingTimer()
            }
        }
    }
    
    private func removePowerNotifications() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
            print("[PowerMonitorService] IOKit notifications removed")
        }
    }
    
    private func powerSourceChanged() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let newPowerInfo = self.getCurrentPowerInfo() {
                // Check if state actually changed
                if let currentInfo = self.currentPowerInfo,
                   currentInfo.state != newPowerInfo.state {
                    
                    self.currentPowerInfo = newPowerInfo
                    
                    // Notify on main thread
                    if let callback = self.stateChangeCallback {
                        DispatchQueue.main.async {
                            callback(newPowerInfo)
                        }
                    }
                    
                    print("[PowerMonitorService] Power state changed via notification: \(newPowerInfo.state.description)")
                } else if self.currentPowerInfo == nil {
                    self.currentPowerInfo = newPowerInfo
                }
            }
        }
    }
}

// MARK: - Objective-C Compatibility

@objc public extension PowerMonitorService {
    /// Objective-C compatible method to check if power is connected
    @objc var isPowerConnected: Bool {
        return currentPowerInfo?.state == .connected
    }
    
    /// Objective-C compatible method to get battery level
    @objc var batteryLevel: Int {
        return currentPowerInfo?.batteryLevel ?? -1
    }
}