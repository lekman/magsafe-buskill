//
//  MockLocationRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of LocationRepository for testing.
//  Provides controllable location behavior for unit tests.
//

import Foundation
@testable import MagSafeGuardDomain
@testable import MagSafeGuardCore

/// Mock implementation of LocationRepository for testing.
/// Allows full control over location behavior in tests.
public actor MockLocationRepository: LocationRepository {

    // MARK: - Properties

    /// Current trust status
    public var isInTrustedLocation = true

    /// Stored trusted locations
    public var trustedLocations: [TrustedLocationDomain] = []

    /// Track method calls
    public private(set) var startMonitoringCalls = 0
    public private(set) var stopMonitoringCalls = 0
    public private(set) var isInTrustedLocationCalls = 0
    public private(set) var addTrustedLocationCalls = 0
    public private(set) var removeTrustedLocationCalls = 0
    public private(set) var getTrustedLocationsCalls = 0

    /// Errors to throw
    public var startMonitoringError: Error?
    public var addLocationError: Error?
    public var removeLocationError: Error?

    /// Active continuation for location changes
    private var continuation: AsyncStream<Bool>.Continuation?

    /// Monitoring state
    public private(set) var isMonitoring = false

    // MARK: - Initialization

    /// Initialize mock repository
    public init() {
        // Add some default trusted locations
        trustedLocations = [
            TrustedLocationBuilder.home().build(),
            TrustedLocationBuilder.office().build()
        ]
    }

    // MARK: - Configuration Methods

    /// Simulate entering a trusted location
    public func simulateEnterTrustedLocation() {
        isInTrustedLocation = true
        continuation?.yield(true)
    }

    /// Simulate leaving a trusted location
    public func simulateLeaveTrustedLocation() {
        isInTrustedLocation = false
        continuation?.yield(false)
    }

    /// Configure with specific trusted locations
    /// - Parameter locations: Locations to set
    public func configureTrustedLocations(_ locations: [TrustedLocationDomain]) {
        trustedLocations = locations
    }

    /// Reset all mock state
    public func reset() {
        isInTrustedLocation = true
        trustedLocations = [
            TrustedLocationBuilder.home().build(),
            TrustedLocationBuilder.office().build()
        ]
        startMonitoringCalls = 0
        stopMonitoringCalls = 0
        isInTrustedLocationCalls = 0
        addTrustedLocationCalls = 0
        removeTrustedLocationCalls = 0
        getTrustedLocationsCalls = 0
        startMonitoringError = nil
        addLocationError = nil
        removeLocationError = nil
        continuation = nil
        isMonitoring = false
    }

    // MARK: - LocationRepository Implementation

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

    public func isInTrustedLocation() async -> Bool {
        isInTrustedLocationCalls += 1
        return isInTrustedLocation
    }

    public func addTrustedLocation(_ location: TrustedLocationDomain) async throws {
        addTrustedLocationCalls += 1

        if let error = addLocationError {
            throw error
        }

        // Check for duplicates
        if trustedLocations.contains(where: { $0.id == location.id }) {
            throw MockError.customError("Location already exists")
        }

        trustedLocations.append(location)
    }

    public func removeTrustedLocation(id: UUID) async throws {
        removeTrustedLocationCalls += 1

        if let error = removeLocationError {
            throw error
        }

        guard let index = trustedLocations.firstIndex(where: { $0.id == id }) else {
            throw MockError.customError("Location not found")
        }

        trustedLocations.remove(at: index)
    }

    public func getTrustedLocations() async -> [TrustedLocationDomain] {
        getTrustedLocationsCalls += 1
        return trustedLocations
    }

    public func observeLocationTrustChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            self.continuation = continuation

            // Emit current state
            continuation.yield(isInTrustedLocation)

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

extension MockLocationRepository {

    /// Simulate location trust changes
    /// - Parameter sequence: Sequence of trust states
    public func simulateLocationSequence(_ sequence: [Bool]) async {
        for trustState in sequence {
            isInTrustedLocation = trustState
            continuation?.yield(trustState)
            // Small delay between changes
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    /// Verify location was added correctly
    /// - Parameter name: Location name to verify
    /// - Returns: True if location exists
    public func verifyLocationExists(named name: String) -> Bool {
        trustedLocations.contains { $0.name == name }
    }

    /// Get location by name
    /// - Parameter name: Location name
    /// - Returns: Location if found
    public func getLocation(named name: String) -> TrustedLocationDomain? {
        trustedLocations.first { $0.name == name }
    }

    /// Configure for authorization error
    public func configureAuthorizationError() {
        startMonitoringError = MockError.unauthorized
    }
}
