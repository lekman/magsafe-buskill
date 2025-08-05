//
//  NetworkFrameworkRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation
import MagSafeGuardDomain
import Network
import Security

/// Network repository error types
public enum NetworkRepositoryError: Error {
    /// Error occurred during storage operations
    case storageError(String)
    /// Network services are unavailable
    case networkUnavailable
    /// Network path monitoring failed to start
    case pathMonitoringFailed
}

/// Network framework-based implementation of NetworkRepository
public final class NetworkFrameworkRepository: NetworkRepository {

    // MARK: - Properties

    private let networkMonitor: NetworkMonitor
    private let trustedNetworksStore: TrustedNetworksStore
    private let changeStream = AsyncStream<NetworkChangeEvent>.makeStream()

    // MARK: - Initialization

    /// Initializes the Network Framework-based repository
    /// - Parameters:
    ///   - networkMonitor: The network monitor instance
    ///   - trustedNetworksStore: Storage for trusted networks
    public init(
        networkMonitor: NetworkMonitor = NetworkMonitor(),
        trustedNetworksStore: TrustedNetworksStore = KeychainTrustedNetworksStore()
    ) {
        self.networkMonitor = networkMonitor
        self.trustedNetworksStore = trustedNetworksStore

        // Set up delegation
        networkMonitor.delegate = self
    }

    // MARK: - NetworkRepository Implementation

    /// Starts monitoring network changes
    public func startMonitoring() async throws {
        // Load trusted networks from store
        let storedNetworks = await trustedNetworksStore.loadTrustedNetworks()
        let ssids = Set(storedNetworks.map { $0.ssid })

        networkMonitor.updateTrustedNetworks(ssids)
        networkMonitor.startMonitoring()
    }

    /// Stops monitoring network changes
    public func stopMonitoring() async {
        networkMonitor.stopMonitoring()
        changeStream.continuation.finish()
    }

    /// Gets the current network information
    public func getCurrentNetworkInfo() async -> NetworkInfo {
        return NetworkInfo(
            isConnected: networkMonitor.isConnected,
            currentSSID: networkMonitor.currentSSID,
            isTrusted: networkMonitor.isOnTrustedNetwork
        )
    }

    /// Adds a network to the trusted list
    public func addTrustedNetwork(_ network: TrustedNetwork) async throws {
        networkMonitor.addTrustedNetwork(network.ssid)

        // Save to store
        var networks = await trustedNetworksStore.loadTrustedNetworks()
        networks.append(network)
        try await trustedNetworksStore.saveTrustedNetworks(networks)
    }

    /// Removes a network from the trusted list
    public func removeTrustedNetwork(ssid: String) async throws {
        networkMonitor.removeTrustedNetwork(ssid)

        // Update store
        var networks = await trustedNetworksStore.loadTrustedNetworks()
        networks.removeAll { $0.ssid == ssid }
        try await trustedNetworksStore.saveTrustedNetworks(networks)
    }

    /// Gets all trusted networks
    public func getTrustedNetworks() async -> [TrustedNetwork] {
        return await trustedNetworksStore.loadTrustedNetworks()
    }

    /// Returns a stream of network change events
    public func observeNetworkChanges() -> AsyncStream<NetworkChangeEvent> {
        return changeStream.stream
    }
}

// MARK: - NetworkMonitorDelegate

extension NetworkFrameworkRepository: NetworkMonitorDelegate {

    /// Called when connecting to an untrusted network
    public func networkMonitorDidConnectToUntrustedNetwork(_ ssid: String) {
        changeStream.continuation.yield(.connectedToNetwork(ssid: ssid, trusted: false))
    }

    /// Called when disconnecting from a trusted network
    public func networkMonitorDidDisconnectFromTrustedNetwork() {
        // We don't have the SSID in this callback, but we know it was trusted
        changeStream.continuation.yield(.disconnectedFromNetwork(ssid: nil, trusted: true))
    }

    /// Called when connecting to a trusted network
    public func networkMonitorDidConnectToTrustedNetwork(_ ssid: String) {
        changeStream.continuation.yield(.connectedToNetwork(ssid: ssid, trusted: true))
    }

    /// Called when network connectivity changes
    public func networkMonitor(didChangeConnectivity isConnected: Bool) {
        changeStream.continuation.yield(.connectivityChanged(isConnected: isConnected))
    }
}

// MARK: - Trusted Networks Storage

/// Protocol for persisting trusted networks
public protocol TrustedNetworksStore {
    /// Saves trusted networks to persistent storage
    func saveTrustedNetworks(_ networks: [TrustedNetwork]) async throws
    /// Loads trusted networks from persistent storage
    func loadTrustedNetworks() async -> [TrustedNetwork]
}

/// Keychain-based secure storage for trusted networks
public actor KeychainTrustedNetworksStore: TrustedNetworksStore {
    private let service = "com.lekman.MagSafeGuard.TrustedNetworks"
    private let account = "trusted-networks"

    /// Initializes keychain storage
    public init() {}

    /// Saves trusted networks to Keychain (encrypted)
    public func saveTrustedNetworks(_ networks: [TrustedNetwork]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(networks.map(NetworkDTO.init))

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new encrypted item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NetworkRepositoryError.storageError("Failed to save to keychain: \(status)")
        }
    }

    /// Loads trusted networks from Keychain (decrypted)
    public func loadTrustedNetworks() async -> [TrustedNetwork] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data else {
            return []
        }

        let decoder = JSONDecoder()
        guard let dtos = try? decoder.decode([NetworkDTO].self, from: data) else { return [] }

        return dtos.map { $0.toDomainModel() }
    }
}

// MARK: - Data Transfer Objects

/// DTO for network persistence
private struct NetworkDTO: Codable {
    let ssid: String
    let addedDate: Date

    init(from domain: TrustedNetwork) {
        self.ssid = domain.ssid
        self.addedDate = domain.addedDate
    }

    func toDomainModel() -> TrustedNetwork {
        return TrustedNetwork(
            ssid: ssid,
            addedDate: addedDate
        )
    }
}
