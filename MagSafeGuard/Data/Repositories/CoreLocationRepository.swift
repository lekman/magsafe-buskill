//
//  CoreLocationRepository.swift
//  MagSafe Guard
//
//  Repository implementation that bridges domain layer to CoreLocation.
//  This is the only class that should contain CoreLocation dependencies.
//

import Foundation
import CoreLocation

/// CoreLocation-based implementation of LocationRepository
public final class CoreLocationRepository: LocationRepository {

    // MARK: - Properties

    private let locationManager: LocationManagerProtocol
    private let trustedLocationsStore: TrustedLocationsStore
    private let changeStream = AsyncStream<Bool>.makeStream()

    // MARK: - Initialization

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

    public func stopMonitoring() async {
        locationManager.stopMonitoring()
        changeStream.continuation.finish()
    }

    public func isInTrustedLocation() async -> Bool {
        return locationManager.isInTrustedLocation
    }

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

    public func removeTrustedLocation(id: UUID) async throws {
        locationManager.removeTrustedLocation(id: id)

        // Update store
        var locations = await trustedLocationsStore.loadTrustedLocations()
        locations.removeAll { $0.id == id }
        try await trustedLocationsStore.saveTrustedLocations(locations)
    }

    public func getTrustedLocations() async -> [TrustedLocationDomain] {
        return await trustedLocationsStore.loadTrustedLocations()
    }

    public func observeLocationTrustChanges() -> AsyncStream<Bool> {
        return changeStream.stream
    }
}

// MARK: - LocationManagerDelegate

extension CoreLocationRepository: LocationManagerDelegate {

    public func locationManagerDidLeaveTrustedLocation() {
        changeStream.continuation.yield(false)
    }

    public func locationManagerDidEnterTrustedLocation() {
        changeStream.continuation.yield(true)
    }

    public func locationManager(didChangeAuthorization status: CLAuthorizationStatus) {
        // Could emit events for authorization changes if needed
    }
}

// MARK: - Trusted Locations Storage

/// Protocol for persisting trusted locations
public protocol TrustedLocationsStore {
    func saveTrustedLocations(_ locations: [TrustedLocationDomain]) async throws
    func loadTrustedLocations() async -> [TrustedLocationDomain]
}

/// UserDefaults-based storage for trusted locations
public actor UserDefaultsTrustedLocationsStore: TrustedLocationsStore {
    private let userDefaults: UserDefaults
    private let key = "MagSafeGuard.TrustedLocations"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveTrustedLocations(_ locations: [TrustedLocationDomain]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(locations.map(LocationDTO.init))
        userDefaults.set(data, forKey: key)
    }

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
