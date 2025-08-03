//
//  CoreLocationRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import CoreLocation
import Foundation

/// CoreLocation-based implementation of LocationRepository
public final class CoreLocationRepository: LocationRepository {

    // MARK: - Properties

    private let locationManager: LocationManagerProtocol
    private let trustedLocationsStore: TrustedLocationsStore
    private let changeStream = AsyncStream<Bool>.makeStream()

    // MARK: - Initialization

    /// Initializes the Core Location-based repository
    /// - Parameters:
    ///   - locationManager: The location manager instance
    ///   - trustedLocationsStore: Storage for trusted locations
    public init(
        locationManager: LocationManagerProtocol,
        trustedLocationsStore: TrustedLocationsStore = UserDefaultsTrustedLocationsStore()
    ) {
        self.locationManager = locationManager
        self.trustedLocationsStore = trustedLocationsStore

        // Set up delegation
        locationManager.delegate = self
    }

    // MARK: - LocationRepository Implementation

    /// Starts monitoring location changes
    public func startMonitoring() async throws {
        // Load trusted locations from store
        let storedLocations = await trustedLocationsStore.loadTrustedLocations()
        let trustedLocations = storedLocations.map { location in
            TrustedLocation(
                name: location.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                radius: location.radius
            )
        }

        locationManager.updateTrustedLocations(trustedLocations)
        locationManager.startMonitoring()
    }

    /// Stops monitoring location changes
    public func stopMonitoring() async {
        locationManager.stopMonitoring()
        changeStream.continuation.finish()
    }

    /// Checks if currently in a trusted location
    public func isInTrustedLocation() async -> Bool {
        return locationManager.isInTrustedLocation
    }

    /// Adds a location to the trusted list
    public func addTrustedLocation(_ location: TrustedLocationDomain) async throws {
        let clLocation = TrustedLocation(
            name: location.name,
            coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            radius: location.radius
        )

        locationManager.addTrustedLocation(clLocation)

        // Save to store
        var locations = await trustedLocationsStore.loadTrustedLocations()
        locations.append(location)
        try await trustedLocationsStore.saveTrustedLocations(locations)
    }

    /// Removes a location from the trusted list
    public func removeTrustedLocation(id: UUID) async throws {
        locationManager.removeTrustedLocation(id: id)

        // Update store
        var locations = await trustedLocationsStore.loadTrustedLocations()
        locations.removeAll { $0.id == id }
        try await trustedLocationsStore.saveTrustedLocations(locations)
    }

    /// Gets all trusted locations
    public func getTrustedLocations() async -> [TrustedLocationDomain] {
        return await trustedLocationsStore.loadTrustedLocations()
    }

    /// Returns a stream of location trust change events
    public func observeLocationTrustChanges() -> AsyncStream<Bool> {
        return changeStream.stream
    }
}

// MARK: - LocationManagerDelegate

extension CoreLocationRepository: LocationManagerDelegate {

    /// Called when leaving a trusted location
    public func locationManagerDidLeaveTrustedLocation() {
        changeStream.continuation.yield(false)
    }

    /// Called when entering a trusted location
    public func locationManagerDidEnterTrustedLocation() {
        changeStream.continuation.yield(true)
    }

    /// Called when location authorization changes
    public func locationManager(didChangeAuthorization status: CLAuthorizationStatus) {
        // Could emit events for authorization changes if needed
    }
}

// MARK: - Trusted Locations Storage

/// Protocol for persisting trusted locations
public protocol TrustedLocationsStore {
    /// Saves trusted locations to persistent storage
    func saveTrustedLocations(_ locations: [TrustedLocationDomain]) async throws
    /// Loads trusted locations from persistent storage
    func loadTrustedLocations() async -> [TrustedLocationDomain]
}

/// UserDefaults-based storage for trusted locations
public actor UserDefaultsTrustedLocationsStore: TrustedLocationsStore {
    private let userDefaults: UserDefaults
    private let key = "MagSafeGuard.TrustedLocations"

    /// Initializes with UserDefaults storage
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Saves trusted locations to UserDefaults
    public func saveTrustedLocations(_ locations: [TrustedLocationDomain]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(locations.map(LocationDTO.init))
        userDefaults.set(data, forKey: key)
    }

    /// Loads trusted locations from UserDefaults
    public func loadTrustedLocations() async -> [TrustedLocationDomain] {
        guard let data = userDefaults.data(forKey: key) else { return [] }

        let decoder = JSONDecoder()
        guard let dtos = try? decoder.decode([LocationDTO].self, from: data) else { return [] }

        return dtos.map { $0.toDomainModel() }
    }
}

// MARK: - Data Transfer Objects

/// DTO for location persistence
private struct LocationDTO: Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double

    init(from domain: TrustedLocationDomain) {
        self.id = domain.id
        self.name = domain.name
        self.latitude = domain.latitude
        self.longitude = domain.longitude
        self.radius = domain.radius
    }

    func toDomainModel() -> TrustedLocationDomain {
        return TrustedLocationDomain(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
    }
}
