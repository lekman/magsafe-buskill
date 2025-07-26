//
//  AutoArmManager.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Manages automatic arming based on location and network conditions
//

import Foundation
import CoreLocation

/// Manages automatic arming of the security system based on location and network conditions.
///
/// AutoArmManager coordinates between LocationManager and NetworkMonitor to provide
/// intelligent automatic arming. It respects user preferences and provides override
/// capabilities for temporary disabling.
///
/// ## Features
/// - Location-based auto-arming (leave trusted locations)
/// - Network-based auto-arming (connect to untrusted networks)
/// - Configurable rules and preferences
/// - Temporary override mechanism
/// - Smart notifications
///
/// ## Usage
/// ```swift
/// let autoArmManager = AutoArmManager(appController: appController)
/// autoArmManager.startMonitoring()
/// ```
///
/// ## Security Considerations
/// - Requires location and network permissions
/// - Respects user privacy by only tracking trusted/untrusted status
/// - All decisions are logged for security audit
public class AutoArmManager: NSObject {
    
    // MARK: - Properties
    
    /// The app controller for arming/disarming
    private let appController: AppController
    
    /// Location manager for geofencing
    private let locationManager = LocationManager()
    
    /// Network monitor for Wi-Fi detection
    private let networkMonitor = NetworkMonitor()
    
    /// User defaults manager for settings
    private let settingsManager = UserDefaultsManager.shared
    
    /// Whether auto-arm is currently active
    public private(set) var isMonitoring = false
    
    /// Whether auto-arm is temporarily disabled
    public private(set) var isTemporarilyDisabled = false
    
    /// Timer for temporary disable
    private var disableTimer: Timer?
    
    /// Last auto-arm trigger reason for deduplication
    private var lastAutoArmReason: String?
    
    /// Time of last auto-arm to prevent rapid triggers
    private var lastAutoArmTime: Date?
    
    /// Minimum time between auto-arm triggers (30 seconds)
    private let autoArmCooldown: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    /// Initializes the auto-arm manager
    /// - Parameter appController: The app controller for security operations
    public init(appController: AppController) {
        self.appController = appController
        super.init()
        
        setupDelegates()
        loadSettings()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func setupDelegates() {
        locationManager.delegate = self
        networkMonitor.delegate = self
    }
    
    private func loadSettings() {
        // Load trusted networks from settings
        let settings = settingsManager.settings
        networkMonitor.updateTrustedNetworks(Set(settings.trustedNetworks))
    }
    
    // MARK: - Public Methods
    
    /// Starts auto-arm monitoring if enabled in settings
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        let settings = settingsManager.settings
        guard settings.autoArmEnabled else {
            print("[AutoArmManager] Auto-arm is disabled in settings")
            return
        }
        
        isMonitoring = true
        
        // Start appropriate monitors based on settings
        if settings.autoArmByLocation {
            locationManager.startMonitoring()
        }
        
        if settings.autoArmOnUntrustedNetwork {
            networkMonitor.startMonitoring()
        }
        
        print("[AutoArmManager] Started monitoring (location: \(settings.autoArmByLocation), network: \(settings.autoArmOnUntrustedNetwork))")
    }
    
    /// Stops all auto-arm monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        locationManager.stopMonitoring()
        networkMonitor.stopMonitoring()
        
        print("[AutoArmManager] Stopped monitoring")
    }
    
    /// Temporarily disables auto-arm for the specified duration
    /// - Parameter duration: How long to disable auto-arm (default: 1 hour)
    public func temporarilyDisable(for duration: TimeInterval = 3600) {
        isTemporarilyDisabled = true
        
        // Cancel existing timer
        disableTimer?.invalidate()
        
        // Set new timer
        disableTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.isTemporarilyDisabled = false
            print("[AutoArmManager] Temporary disable expired")
        }
        
        print("[AutoArmManager] Temporarily disabled for \(Int(duration/60)) minutes")
        
        // Show notification
        NotificationService.shared.showNotification(
            title: "Auto-Arm Disabled",
            message: "Automatic arming disabled for \(Int(duration/60)) minutes"
        )
    }
    
    /// Re-enables auto-arm if it was temporarily disabled
    public func cancelTemporaryDisable() {
        guard isTemporarilyDisabled else { return }
        
        isTemporarilyDisabled = false
        disableTimer?.invalidate()
        disableTimer = nil
        
        print("[AutoArmManager] Temporary disable cancelled")
    }
    
    /// Updates settings and restarts monitoring if needed
    public func updateSettings() {
        loadSettings()
        
        // Restart monitoring to apply new settings
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    /// Adds a trusted location for auto-arm
    /// - Parameter location: The location to add
    public func addTrustedLocation(_ location: TrustedLocation) {
        locationManager.addTrustedLocation(location)
    }
    
    /// Removes a trusted location
    /// - Parameter id: The ID of the location to remove
    public func removeTrustedLocation(id: UUID) {
        locationManager.removeTrustedLocation(id: id)
    }
    
    /// Gets all trusted locations
    /// - Returns: Array of trusted locations
    public func getTrustedLocations() -> [TrustedLocation] {
        return locationManager.trustedLocations
    }
    
    // MARK: - Private Methods
    
    private func shouldTriggerAutoArm() -> Bool {
        // Check if temporarily disabled
        if isTemporarilyDisabled {
            print("[AutoArmManager] Auto-arm skipped - temporarily disabled")
            return false
        }
        
        // Check if already armed
        if appController.currentState != .disarmed {
            print("[AutoArmManager] Auto-arm skipped - already armed")
            return false
        }
        
        // Check cooldown period
        if let lastTime = lastAutoArmTime,
           Date().timeIntervalSince(lastTime) < autoArmCooldown {
            print("[AutoArmManager] Auto-arm skipped - cooldown period")
            return false
        }
        
        return true
    }
    
    private func triggerAutoArm(reason: String) {
        guard shouldTriggerAutoArm() else { return }
        
        // Update tracking
        lastAutoArmReason = reason
        lastAutoArmTime = Date()
        
        // Log the auto-arm event
        appController.logEvent(.autoArmTriggered, details: reason)
        
        // Show notification before arming
        NotificationService.shared.showNotification(
            title: "Auto-Arm Activated",
            message: reason
        )
        
        // Arm the system
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.appController.arm { result in
                switch result {
                case .success:
                    print("[AutoArmManager] Successfully auto-armed: \(reason)")
                case .failure(let error):
                    print("[AutoArmManager] Failed to auto-arm: \(error)")
                    NotificationService.shared.showNotification(
                        title: "Auto-Arm Failed",
                        message: "Could not arm system: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
}

// MARK: - LocationManagerDelegate

extension AutoArmManager: LocationManagerDelegate {
    
    public func locationManagerDidLeaveTrustedLocation() {
        print("[AutoArmManager] Left trusted location")
        
        let settings = settingsManager.settings
        guard settings.autoArmEnabled && settings.autoArmByLocation else { return }
        
        triggerAutoArm(reason: "Left trusted location")
    }
    
    public func locationManagerDidEnterTrustedLocation() {
        print("[AutoArmManager] Entered trusted location")
        // Could potentially auto-disarm here if desired
    }
    
    public func locationManager(didChangeAuthorization status: CLAuthorizationStatus) {
        print("[AutoArmManager] Location authorization changed: \(status.rawValue)")
        
        if status == .denied || status == .restricted {
            NotificationService.shared.showNotification(
                title: "Location Permission Required",
                message: "Location-based auto-arm requires location permission"
            )
        }
    }
}

// MARK: - NetworkMonitorDelegate

extension AutoArmManager: NetworkMonitorDelegate {
    
    public func networkMonitorDidConnectToUntrustedNetwork(_ ssid: String) {
        print("[AutoArmManager] Connected to untrusted network: \(ssid)")
        
        let settings = settingsManager.settings
        guard settings.autoArmEnabled && settings.autoArmOnUntrustedNetwork else { return }
        
        triggerAutoArm(reason: "Connected to untrusted network: \(ssid)")
    }
    
    public func networkMonitorDidDisconnectFromTrustedNetwork() {
        print("[AutoArmManager] Disconnected from trusted network")
        
        let settings = settingsManager.settings
        guard settings.autoArmEnabled && settings.autoArmOnUntrustedNetwork else { return }
        
        triggerAutoArm(reason: "Disconnected from trusted network")
    }
    
    public func networkMonitorDidConnectToTrustedNetwork(_ ssid: String) {
        print("[AutoArmManager] Connected to trusted network: \(ssid)")
        // Could potentially auto-disarm here if desired
    }
    
    public func networkMonitor(didChangeConnectivity isConnected: Bool) {
        print("[AutoArmManager] Network connectivity changed: \(isConnected)")
        
        if !isConnected {
            // Lost all network connectivity
            let settings = settingsManager.settings
            guard settings.autoArmEnabled && settings.autoArmOnUntrustedNetwork else { return }
            
            triggerAutoArm(reason: "Lost network connectivity")
        }
    }
}

// MARK: - Public Status Extension

public extension AutoArmManager {
    
    /// Current auto-arm status summary
    var statusSummary: String {
        if !settingsManager.settings.autoArmEnabled {
            return "Auto-arm disabled"
        }
        
        if isTemporarilyDisabled {
            return "Auto-arm temporarily disabled"
        }
        
        var components: [String] = []
        
        if settingsManager.settings.autoArmByLocation {
            let locationStatus = locationManager.isInTrustedLocation ? "in trusted location" : "outside trusted location"
            components.append("Location: \(locationStatus)")
        }
        
        if settingsManager.settings.autoArmOnUntrustedNetwork {
            let networkStatus = networkMonitor.statusDescription
            components.append("Network: \(networkStatus)")
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Whether any auto-arm condition is currently met
    var isAutoArmConditionMet: Bool {
        let settings = settingsManager.settings
        
        if settings.autoArmByLocation && !locationManager.isInTrustedLocation {
            return true
        }
        
        if settings.autoArmOnUntrustedNetwork && networkMonitor.shouldAutoArm {
            return true
        }
        
        return false
    }
}