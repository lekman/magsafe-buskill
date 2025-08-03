//
//  NetworkFrameworkRepository.swift
//  MagSafe Guard
//
//  Repository implementation that bridges domain layer to Network framework.
//  This is the only class that should contain Network framework dependencies.
//

import Foundation
import Network

/// Network framework-based implementation of NetworkRepository
public final class NetworkFrameworkRepository: NetworkRepository {

    // MARK: - Properties

    private let networkMonitor: NetworkMonitor
    private let trustedNetworksStore: TrustedNetworksStore
    private let changeStream = AsyncStream<NetworkChangeEvent>.makeStream()

    // MARK: - Initialization

    public init(
        networkMonitor: NetworkMonitor = NetworkMonitor(),
        trustedNetworksStore: TrustedNetworksStore = UserDefaultsTrustedNetworksStore()
    ) {
        self.networkMonitor = networkMonitor
        self.trustedNetworksStore = trustedNetworksStore

        // Set up delegation
        networkMonitor.delegate = self
    }

    // MARK: - NetworkRepository Implementation

    public func startMonitoring() async throws {
        // Load trusted networks from store
        let storedNetworks = await trustedNetworksStore.loadTrustedNetworks()
        let ssids = Set(storedNetworks.map { $0.ssid })

        networkMonitor.updateTrustedNetworks(ssids)
        networkMonitor.startMonitoring()
    }

    public func stopMonitoring() async {
        networkMonitor.stopMonitoring()
        changeStream.continuation.finish()
    }

    public func getCurrentNetworkInfo() async -> NetworkInfo {
        return NetworkInfo(
            isConnected: networkMonitor.isConnected,
            currentSSID: networkMonitor.currentSSID,
            isTrusted: networkMonitor.isOnTrustedNetwork
        )
    }

    public func addTrustedNetwork(_ network: TrustedNetwork) async throws {
        networkMonitor.addTrustedNetwork(network.ssid)

        // Save to store
        var networks = await trustedNetworksStore.loadTrustedNetworks()
        networks.append(network)
        try await trustedNetworksStore.saveTrustedNetworks(networks)
    }

    public func removeTrustedNetwork(ssid: String) async throws {
        networkMonitor.removeTrustedNetwork(ssid)

        // Update store
        var networks = await trustedNetworksStore.loadTrustedNetworks()
        networks.removeAll { $0.ssid == ssid }
        try await trustedNetworksStore.saveTrustedNetworks(networks)
    }

    public func getTrustedNetworks() async -> [TrustedNetwork] {
        return await trustedNetworksStore.loadTrustedNetworks()
    }

    public func observeNetworkChanges() -> AsyncStream<NetworkChangeEvent> {
        return changeStream.stream
    }
}

// MARK: - NetworkMonitorDelegate

extension NetworkFrameworkRepository: NetworkMonitorDelegate {

    public func networkMonitorDidConnectToUntrustedNetwork(_ ssid: String) {
        changeStream.continuation.yield(.connectedToNetwork(ssid: ssid, trusted: false))
    }

    public func networkMonitorDidDisconnectFromTrustedNetwork() {
        // We don't have the SSID in this callback, but we know it was trusted
        changeStream.continuation.yield(.disconnectedFromNetwork(ssid: nil, trusted: true))
    }

    public func networkMonitorDidConnectToTrustedNetwork(_ ssid: String) {
        changeStream.continuation.yield(.connectedToNetwork(ssid: ssid, trusted: true))
    }

    public func networkMonitor(didChangeConnectivity isConnected: Bool) {
        changeStream.continuation.yield(.connectivityChanged(isConnected: isConnected))
    }
}

// MARK: - Trusted Networks Storage

/// Protocol for persisting trusted networks
public protocol TrustedNetworksStore {
    func saveTrustedNetworks(_ networks: [TrustedNetwork]) async throws
    func loadTrustedNetworks() async -> [TrustedNetwork]
}

/// UserDefaults-based storage for trusted networks
public actor UserDefaultsTrustedNetworksStore: TrustedNetworksStore {
    private let userDefaults: UserDefaults
    private let key = "MagSafeGuard.TrustedNetworks"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveTrustedNetworks(_ networks: [TrustedNetwork]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(networks.map(NetworkDTO.init))
        userDefaults.set(data, forKey: key)
    }

    public func loadTrustedNetworks() async -> [TrustedNetwork] {
        guard let data = userDefaults.data(forKey: key) else { return [] }

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
