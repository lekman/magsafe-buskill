//
//  NetworkMonitor.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Monitors network connectivity and Wi-Fi changes for auto-arm functionality
//

import CoreWLAN
import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

/// Protocol for network-based auto-arm events
public protocol NetworkMonitorDelegate: AnyObject {
    /// Called when connected to an untrusted network
    func networkMonitorDidConnectToUntrustedNetwork(_ ssid: String)
    /// Called when disconnected from a trusted network
    func networkMonitorDidDisconnectFromTrustedNetwork()
    /// Called when connected to a trusted network
    func networkMonitorDidConnectToTrustedNetwork(_ ssid: String)
    /// Called when network connectivity changes
    func networkMonitor(didChangeConnectivity isConnected: Bool)
}

/// Monitors network connectivity and Wi-Fi changes for auto-arm functionality.
///
/// NetworkMonitor tracks Wi-Fi network changes and can trigger auto-arm
/// when connecting to untrusted networks or disconnecting from trusted ones.
/// It uses the Network framework for efficient monitoring with minimal overhead.
///
/// ## Features
/// - Real-time Wi-Fi SSID detection
/// - Trusted network management
/// - Background network monitoring
/// - Connectivity state tracking
///
/// ## Usage
/// ```swift
/// let monitor = NetworkMonitor()
/// monitor.delegate = self
/// monitor.addTrustedNetwork("HomeWiFi")
/// monitor.startMonitoring()
/// ```
///
/// ## Security Note
/// Network SSIDs are stored locally and never transmitted.
/// The system only tracks whether a network is trusted, not any
/// authentication credentials or network details.
public class NetworkMonitor {

    // MARK: - Properties

    /// Delegate for receiving network-based events
    public weak var delegate: NetworkMonitorDelegate?

    /// Currently configured trusted network SSIDs
    public private(set) var trustedNetworks: Set<String> = []

    /// Whether network monitoring is currently active
    public private(set) var isMonitoring = false

    /// Current Wi-Fi SSID if connected
    public private(set) var currentSSID: String?

    /// Whether currently connected to any network
    public private(set) var isConnected = false

    /// Whether currently connected to a trusted network
    public private(set) var isOnTrustedNetwork = false

    // Private properties
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.magsafeguard.networkmonitor")
    private var ssidCheckTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private let trustedNetworksKey = "MagSafeGuard.TrustedNetworks"

    // MARK: - Initialization

    /// Initializes the network monitor
    public init() {
        loadTrustedNetworks()
        setupNetworkMonitor()
    }

    deinit {
        stopMonitoring()
    }

    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }

    // MARK: - Public Methods

    /// Starts monitoring network changes
    public func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        monitor.start(queue: monitorQueue)

        // Start periodic SSID checks
        startSSIDMonitoring()

        // Get initial state
        checkCurrentNetwork()
    }

    /// Stops network monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }

        isMonitoring = false
        monitor.cancel()
        stopSSIDMonitoring()
    }

    /// Adds a network to the trusted list
    /// - Parameter ssid: The SSID of the network to trust
    public func addTrustedNetwork(_ ssid: String) {
        guard !ssid.isEmpty else { return }

        trustedNetworks.insert(ssid)
        saveTrustedNetworks()

        // Check if we just trusted the current network
        if ssid == currentSSID {
            isOnTrustedNetwork = true
            delegate?.networkMonitorDidConnectToTrustedNetwork(ssid)
        }
    }

    /// Removes a network from the trusted list
    /// - Parameter ssid: The SSID of the network to remove
    public func removeTrustedNetwork(_ ssid: String) {
        trustedNetworks.remove(ssid)
        saveTrustedNetworks()

        // Check if we just untrusted the current network
        if ssid == currentSSID {
            isOnTrustedNetwork = false
            delegate?.networkMonitorDidConnectToUntrustedNetwork(ssid)
        }
    }

    /// Updates the list of trusted networks
    /// - Parameter networks: New set of trusted network SSIDs
    public func updateTrustedNetworks(_ networks: Set<String>) {
        trustedNetworks = networks
        saveTrustedNetworks()

        // Re-evaluate current network
        checkCurrentNetwork()
    }

    /// Gets the current Wi-Fi SSID
    /// - Returns: The current SSID or nil if not connected to Wi-Fi
    public func getCurrentSSID() -> String? {
        #if os(macOS)
        // Use CoreWLAN for macOS
        let client = CWWiFiClient.shared()
        let interface = client.interface()
        return interface?.ssid()
        #else
        // Use SystemConfiguration for iOS (if we ever support it)
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }

        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                  let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            return ssid
        }
        return nil
        #endif
    }

    /// Checks if currently on a trusted network
    /// - Returns: true if on a trusted network, false otherwise
    public func isCurrentNetworkTrusted() -> Bool {
        guard let ssid = currentSSID else { return false }
        return trustedNetworks.contains(ssid)
    }

    // MARK: - Private Methods

    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = (path.status == .satisfied)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Notify connectivity change
            if wasConnected != self.isConnected {
                self.delegate?.networkMonitor(didChangeConnectivity: self.isConnected)
            }

            // Check for Wi-Fi changes
            if self.isConnected {
                self.checkCurrentNetwork()
            } else {
                // Disconnected from network
                if self.isOnTrustedNetwork {
                    self.delegate?.networkMonitorDidDisconnectFromTrustedNetwork()
                }
                self.currentSSID = nil
                self.isOnTrustedNetwork = false
            }
        }
    }

    private func startSSIDMonitoring() {
        // Check SSID every 5 seconds to detect Wi-Fi network changes
        ssidCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkCurrentNetwork()
        }
    }

    private func stopSSIDMonitoring() {
        ssidCheckTimer?.invalidate()
        ssidCheckTimer = nil
    }

    private func checkCurrentNetwork() {
        let previousSSID = currentSSID
        let wasOnTrustedNetwork = isOnTrustedNetwork

        currentSSID = getCurrentSSID()

        if let ssid = currentSSID {
            isOnTrustedNetwork = trustedNetworks.contains(ssid)

            // Check if network changed
            if ssid != previousSSID {
                Log.infoSensitive("Connected to network", value: "\(ssid) (trusted: \(isOnTrustedNetwork))", category: .network)

                if isOnTrustedNetwork {
                    delegate?.networkMonitorDidConnectToTrustedNetwork(ssid)
                } else {
                    delegate?.networkMonitorDidConnectToUntrustedNetwork(ssid)
                }
            }
        } else {
            isOnTrustedNetwork = false

            // Lost Wi-Fi connection
            if wasOnTrustedNetwork {
                delegate?.networkMonitorDidDisconnectFromTrustedNetwork()
            }
        }
    }

    private func loadTrustedNetworks() {
        // First try to load from our own storage
        if let networks = userDefaults.stringArray(forKey: trustedNetworksKey) {
            trustedNetworks = Set(networks)
        } else {
            // Fall back to loading from Settings if available
            let settings = UserDefaultsManager.shared.settings
            trustedNetworks = Set(settings.trustedNetworks)
        }
    }

    private func saveTrustedNetworks() {
        // Only update via UserDefaultsManager to avoid duplicate saves
        UserDefaultsManager.shared.updateSetting(\.trustedNetworks, value: Array(trustedNetworks))
    }
}

// MARK: - Network Status Extension

/// Extension to provide human-readable network status
public extension NetworkMonitor {

    /// Current network status description
    var statusDescription: String {
        if !isConnected {
            return "Disconnected"
        }

        if let ssid = currentSSID {
            return isOnTrustedNetwork ? "Connected to trusted network: \(ssid)" : "Connected to untrusted network: \(ssid)"
        }

        return "Connected (no Wi-Fi)"
    }

    /// Whether auto-arm should be active based on current network
    var shouldAutoArm: Bool {
        // Auto-arm if:
        // 1. Not connected to any network, OR
        // 2. Connected to an untrusted network
        return !isConnected || (currentSSID != nil && !isOnTrustedNetwork)
    }
}
