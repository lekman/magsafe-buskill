//
//  PowerMonitorService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//

import Foundation
import IOKit.ps

/// Service responsible for monitoring power adapter connection status.
///
/// PowerMonitorService provides real-time monitoring of power adapter connection
/// and disconnection events using macOS IOKit APIs. It supports both notification-based
/// monitoring (preferred) and polling-based fallback for maximum reliability.
///
/// ## Architecture
///
/// The service operates in two modes:
/// - **Notification Mode**: Uses IOKit power source notifications for immediate detection
/// - **Polling Mode**: Falls back to timer-based polling if notifications fail
///
/// ## Usage
///
/// ```swift
/// PowerMonitorService.shared.startMonitoring { powerInfo in
///     if powerInfo.state == .disconnected {
///         // Handle power disconnection
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe. Callbacks are always delivered on the main queue
/// for UI updates, while internal processing happens on a dedicated serial queue.
///
/// ## Performance
///
/// - Notification mode: Zero CPU overhead when idle
/// - Polling mode: 100ms intervals for responsive detection
/// - Automatic fallback ensures reliability across different macOS versions
public class PowerMonitorService: NSObject {

    // MARK: - Types

    /// Re-export types from PowerMonitorCore for backward compatibility
    public typealias PowerState = PowerMonitorCore.PowerState
    /// Re-exported power information structure from PowerMonitorCore
    public typealias PowerInfo = PowerMonitorCore.PowerInfo

    /// Callback type for power state changes.
    ///
    /// Called whenever a power state change is detected. The callback receives
    /// complete power information including state, battery level, and charging status.
    /// Always invoked on the main queue for UI safety.
    public typealias PowerStateCallback = (PowerInfo) -> Void

    // MARK: - Properties

    /// Shared instance for singleton pattern.
    ///
    /// The shared instance provides global access to power monitoring functionality.
    /// All components should use this instance rather than creating their own.
    public static let shared = PowerMonitorService()

    /// Current power state information.
    ///
    /// Returns the most recently captured power information, or nil if
    /// monitoring hasn't started or no valid data has been received.
    /// This property is thread-safe and can be accessed from any queue.
    public var currentPowerInfo: PowerInfo? {
        return core.currentPowerInfo
    }

    /// Polling interval in seconds (100ms as per PRD)
    private let pollingInterval: TimeInterval = 0.1

    /// Timer for polling power state
    private var pollingTimer: Timer?

    /// Callback for state changes
    private var stateChangeCallback: PowerStateCallback?

    /// Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.magsafeguard.powermonitor", qos: .utility)

    /// Whether power monitoring is currently active.
    ///
    /// True when monitoring has been started and is actively checking for
    /// power state changes. False when stopped or before first start.
    private(set) public var isMonitoring = false

    /// IOKit notification run loop source
    private var runLoopSource: CFRunLoopSource?

    /// Flag to use notification-based monitoring instead of polling
    private let useNotifications = true

    /// Core logic handler
    internal let core = PowerMonitorCore(pollingInterval: 0.1)

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Start monitoring power state changes.
    ///
    /// Begins monitoring for power adapter connection and disconnection events.
    /// The callback is invoked immediately with the current power state, then
    /// called again whenever changes are detected.
    ///
    /// The service automatically chooses the best monitoring method (notifications
    /// vs polling) and handles fallbacks for maximum reliability.
    ///
    /// - Parameter callback: Closure called when power state changes
    ///   (always invoked on main queue)
    ///
    /// - Note: Only one monitoring session can be active at a time.
    ///   Subsequent calls while monitoring is active are ignored.
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
                // Update core's state
                _ = self.core.hasPowerStateChanged(newInfo: powerInfo)

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

    /// Stop monitoring power state changes.
    ///
    /// Stops all power monitoring activity and cleans up resources.
    /// After calling this method, no further callbacks will be invoked
    /// until monitoring is started again.
    ///
    /// Safe to call multiple times or when monitoring is not active.
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

    /// Get current power information directly from the system.
    ///
    /// Performs an immediate query of the system's power sources via IOKit
    /// to get the latest power state information. This method bypasses any
    /// cached state and always returns fresh data.
    ///
    /// - Returns: Current power information, or nil if system query fails
    ///
    /// - Note: This method performs IOKit calls and should not be called
    ///   frequently. Use the monitoring callback for regular updates.
    public func getCurrentPowerInfo() -> PowerInfo? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        var sourceDicts: [[String: Any]] = []
        for source in sources {
            if let sourceDict = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                sourceDicts.append(sourceDict)
            }
        }

        return core.processPowerSourceInfo(sourceDicts)
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

            if let newPowerInfo = self.getCurrentPowerInfo(),
               self.core.hasPowerStateChanged(newInfo: newPowerInfo) {
                // Notify on main thread
                if let callback = self.stateChangeCallback {
                    DispatchQueue.main.async {
                        callback(newPowerInfo)
                    }
                }

                print("[PowerMonitorService] Power state changed to: \(newPowerInfo.state.description)")
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

            if let newPowerInfo = self.getCurrentPowerInfo(),
               self.core.hasPowerStateChanged(newInfo: newPowerInfo) {
                // Notify on main thread
                if let callback = self.stateChangeCallback {
                    DispatchQueue.main.async {
                        callback(newPowerInfo)
                    }
                }

                print("[PowerMonitorService] Power state changed via notification: \(newPowerInfo.state.description)")
            }
        }
    }
}

// MARK: - Objective-C Compatibility

/// Objective-C compatibility extensions for PowerMonitorService
@objc public extension PowerMonitorService {
    /// Objective-C compatible property to check if power is connected.
    ///
    /// Provides simple boolean power state for Objective-C code that needs
    /// basic connected/disconnected status without Swift optionals.
    ///
    /// - Returns: True if external power is connected, false otherwise
    var isPowerConnected: Bool {
        return core.isPowerConnected()
    }

    /// Objective-C compatible property to get battery level.
    ///
    /// Provides battery charge percentage for Objective-C code that cannot
    /// handle Swift optionals. Uses -1 to indicate unavailable data.
    ///
    /// - Returns: Battery level (0-100) or -1 if unavailable
    var batteryLevel: Int {
        return core.getBatteryLevel()
    }
}
