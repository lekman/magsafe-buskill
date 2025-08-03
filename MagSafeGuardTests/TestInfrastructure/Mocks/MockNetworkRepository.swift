//
//  MockNetworkRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of NetworkRepository for testing.
//  Provides controllable network behavior for unit tests.
//

import Foundation
@testable import MagSafeGuard

/// Mock implementation of NetworkRepository for testing.
/// Allows full control over network behavior in tests.
public actor MockNetworkRepository: NetworkRepository {

    // MARK: - Properties

    /// Current network info
    public var currentNetworkInfo = NetworkInfoBuilder.trustedNetwork().build()

    /// Stored trusted networks
    public var trustedNetworks: [TrustedNetwork] = []

    /// Track method calls
    public private(set) var startMonitoringCalls = 0
    public private(set) var stopMonitoringCalls = 0
    public private(set) var getCurrentNetworkInfoCalls = 0
    public private(set) var addTrustedNetworkCalls = 0
    public private(set) var removeTrustedNetworkCalls = 0
    public private(set) var getTrustedNetworksCalls = 0

    /// Errors to throw
    public var startMonitoringError: Error?
    public var addNetworkError: Error?
    public var removeNetworkError: Error?

    /// Active continuation for network changes
    private var continuation: AsyncStream<NetworkChangeEvent>.Continuation?

    /// Monitoring state
    public private(set) var isMonitoring = false

    // MARK: - Initialization

    /// Initialize mock repository
    public init() {
        // Add some default trusted networks
        trustedNetworks = [
            TrustedNetworkBuilder.homeWiFi().build(),
            TrustedNetworkBuilder.officeWiFi().build()
        ]
    }

    // MARK: - Configuration Methods

    /// Simulate network connection
    /// - Parameters:
    ///   - ssid: Network SSID
    ///   - trusted: Whether network is trusted
    public func simulateNetworkConnection(ssid: String, trusted: Bool) {
        currentNetworkInfo = NetworkInfo(
            isConnected: true,
            currentSSID: ssid,
            isTrusted: trusted
        )
        continuation?.yield(.connectedToNetwork(ssid: ssid, trusted: trusted))
    }

    /// Simulate network disconnection
    public func simulateNetworkDisconnection() {
        let previousSSID = currentNetworkInfo.currentSSID
        let wasTrusted = currentNetworkInfo.isTrusted

        currentNetworkInfo = NetworkInfo(
            isConnected: false,
            currentSSID: nil,
            isTrusted: false
        )
        continuation?.yield(.disconnectedFromNetwork(ssid: previousSSID, trusted: wasTrusted))
    }

    /// Simulate connectivity change
    /// - Parameter connected: New connectivity state
    public func simulateConnectivityChange(connected: Bool) {
        currentNetworkInfo = NetworkInfo(
            isConnected: connected,
            currentSSID: connected ? currentNetworkInfo.currentSSID : nil,
            isTrusted: connected ? currentNetworkInfo.isTrusted : false
        )
        continuation?.yield(.connectivityChanged(isConnected: connected))
    }

    /// Configure current network state
    /// - Parameter info: Network info to set
    public func configureNetworkInfo(_ info: NetworkInfo) {
        currentNetworkInfo = info
    }

    /// Reset all mock state
    public func reset() {
        currentNetworkInfo = NetworkInfoBuilder.trustedNetwork().build()
        trustedNetworks = [
            TrustedNetworkBuilder.homeWiFi().build(),
            TrustedNetworkBuilder.officeWiFi().build()
        ]
        startMonitoringCalls = 0
        stopMonitoringCalls = 0
        getCurrentNetworkInfoCalls = 0
        addTrustedNetworkCalls = 0
        removeTrustedNetworkCalls = 0
        getTrustedNetworksCalls = 0
        startMonitoringError = nil
        addNetworkError = nil
        removeNetworkError = nil
        continuation = nil
        isMonitoring = false
    }

    // MARK: - NetworkRepository Implementation

    public func startMonitoring() async throws {
        startMonitoringCalls += 1

        if let error = startMonitoringError {
            throw error
        }

        isMonitoring = true
    }

    public func stopMonitoring() async {
        stopMonitoringCalls += 1
        isMonitoring = false
        continuation?.finish()
    }

    public func getCurrentNetworkInfo() async -> NetworkInfo {
        getCurrentNetworkInfoCalls += 1
        return currentNetworkInfo
    }

    public func addTrustedNetwork(_ network: TrustedNetwork) async throws {
        addTrustedNetworkCalls += 1

        if let error = addNetworkError {
            throw error
        }

        // Check for duplicates
        if trustedNetworks.contains(where: { $0.ssid == network.ssid }) {
            throw MockError.customError("Network already exists")
        }

        trustedNetworks.append(network)

        // Update current network trust status if connected to this network
        if currentNetworkInfo.currentSSID == network.ssid {
            currentNetworkInfo = NetworkInfo(
                isConnected: true,
                currentSSID: network.ssid,
                isTrusted: true
            )
        }
    }

    public func removeTrustedNetwork(ssid: String) async throws {
        removeTrustedNetworkCalls += 1

        if let error = removeNetworkError {
            throw error
        }

        guard let index = trustedNetworks.firstIndex(where: { $0.ssid == ssid }) else {
            throw MockError.customError("Network not found")
        }

        trustedNetworks.remove(at: index)

        // Update current network trust status if connected to this network
        if currentNetworkInfo.currentSSID == ssid {
            currentNetworkInfo = NetworkInfo(
                isConnected: true,
                currentSSID: ssid,
                isTrusted: false
            )
        }
    }

    public func getTrustedNetworks() async -> [TrustedNetwork] {
        getTrustedNetworksCalls += 1
        return trustedNetworks
    }

    public func observeNetworkChanges() -> AsyncStream<NetworkChangeEvent> {
        AsyncStream { continuation in
            self.continuation = continuation

            continuation.onTermination = { _ in
                Task { await self.handleTermination() }
            }
        }
    }

    private func handleTermination() {
        continuation = nil
    }
}

// MARK: - Test Helpers

extension MockNetworkRepository {

    /// Simulate a sequence of network changes
    /// - Parameter events: Events to emit
    public func simulateNetworkSequence(_ events: [NetworkChangeEvent]) async {
        for event in events {
            continuation?.yield(event)

            // Update current state based on event
            switch event {
            case .connectedToNetwork(let ssid, let trusted):
                currentNetworkInfo = NetworkInfo(
                    isConnected: true,
                    currentSSID: ssid,
                    isTrusted: trusted
                )
            case .disconnectedFromNetwork:
                currentNetworkInfo = NetworkInfo(
                    isConnected: false,
                    currentSSID: nil,
                    isTrusted: false
                )
            case .connectivityChanged(let isConnected):
                currentNetworkInfo = NetworkInfo(
                    isConnected: isConnected,
                    currentSSID: isConnected ? currentNetworkInfo.currentSSID : nil,
                    isTrusted: isConnected ? currentNetworkInfo.isTrusted : false
                )
            }

            // Small delay between changes
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    /// Verify network was added correctly
    /// - Parameter ssid: Network SSID to verify
    /// - Returns: True if network exists
    public func verifyNetworkExists(ssid: String) -> Bool {
        trustedNetworks.contains { $0.ssid == ssid }
    }

    /// Check if currently connected to specific network
    /// - Parameter ssid: Network SSID
    /// - Returns: True if connected to that network
    public func isConnectedTo(ssid: String) -> Bool {
        currentNetworkInfo.isConnected && currentNetworkInfo.currentSSID == ssid
    }

    /// Configure for network error scenario
    public func configureNetworkError() {
        startMonitoringError = MockError.connectionLost
    }

    /// Simulate roaming between networks
    /// - Parameters:
    ///   - fromSSID: Current network
    ///   - toSSID: New network
    ///   - toTrusted: Whether new network is trusted
    public func simulateRoaming(from fromSSID: String, to toSSID: String, toTrusted: Bool) {
        // Disconnect from current
        continuation?.yield(.disconnectedFromNetwork(
            ssid: fromSSID,
            trusted: currentNetworkInfo.isTrusted
        ))

        // Connect to new
        continuation?.yield(.connectedToNetwork(ssid: toSSID, trusted: toTrusted))

        // Update state
        currentNetworkInfo = NetworkInfo(
            isConnected: true,
            currentSSID: toSSID,
            isTrusted: toTrusted
        )
    }
}
