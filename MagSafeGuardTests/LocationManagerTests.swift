//
//  LocationManagerTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for location-based auto-arm functionality
//

import CoreLocation
@testable import MagSafeGuard
import XCTest

final class LocationManagerTests: XCTestCase {

    var locationManager: LocationManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Skip all location tests in CI
        if TestEnvironment.isCI {
            throw XCTSkip("Skipping LocationManager tests in CI environment")
        }

        // Clear any stored locations
        UserDefaults.standard.removeObject(forKey: "MagSafeGuard.TrustedLocations")

        locationManager = LocationManager()
    }

    override func tearDown() {
        locationManager?.stopMonitoring()
        locationManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testLocationManagerInitialization() {
        XCTAssertNotNil(locationManager)
        XCTAssertFalse(locationManager.isMonitoring)
        XCTAssertNil(locationManager.currentLocation)
        XCTAssertFalse(locationManager.isInTrustedLocation)
        XCTAssertTrue(locationManager.trustedLocations.isEmpty)
    }

    // MARK: - Trusted Location Management Tests

    func testAddTrustedLocation() {
        let location = TrustedLocation(
            name: "Home",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )

        locationManager.addTrustedLocation(location)

        XCTAssertEqual(locationManager.trustedLocations.count, 1)
        XCTAssertEqual(locationManager.trustedLocations.first?.name, "Home")
    }

    func testRemoveTrustedLocation() {
        // Add location first
        let location = TrustedLocation(
            name: "Office",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 200
        )
        locationManager.addTrustedLocation(location)

        // Then remove it
        locationManager.removeTrustedLocation(id: location.id)

        XCTAssertTrue(locationManager.trustedLocations.isEmpty)
    }

    func testUpdateTrustedLocations() {
        let locations = [
            TrustedLocation(name: "Home", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), radius: 100),
            TrustedLocation(name: "Office", coordinate: CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811), radius: 150)
        ]

        locationManager.updateTrustedLocations(locations)

        XCTAssertEqual(locationManager.trustedLocations.count, 2)
    }

    // MARK: - Location Checking Tests

    func testCheckIfInTrustedLocationWithNoCurrentLocation() {
        // Add a trusted location
        let location = TrustedLocation(
            name: "Test",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )
        locationManager.addTrustedLocation(location)

        // Without current location, should return false
        XCTAssertFalse(locationManager.checkIfInTrustedLocation())
    }

    // MARK: - Persistence Tests

    func testTrustedLocationsPersistence() {
        // Add locations
        let location1 = TrustedLocation(name: "Home", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), radius: 100)
        let location2 = TrustedLocation(name: "Office", coordinate: CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811), radius: 150)

        locationManager.addTrustedLocation(location1)
        locationManager.addTrustedLocation(location2)

        // Create new manager to test loading
        let newManager = LocationManager()

        XCTAssertEqual(newManager.trustedLocations.count, 2)
        XCTAssertTrue(newManager.trustedLocations.contains { $0.name == "Home" })
        XCTAssertTrue(newManager.trustedLocations.contains { $0.name == "Office" })
    }

    // MARK: - TrustedLocation Tests

    func testTrustedLocationEquality() {
        let location1 = TrustedLocation(
            name: "Home",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )

        let location2 = TrustedLocation(
            name: "Home",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100
        )

        // Different IDs, so not equal
        XCTAssertNotEqual(location1, location2)

        // Same location
        XCTAssertEqual(location1, location1)
    }

    func testTrustedLocationCodable() throws {
        let location = TrustedLocation(
            name: "Test Location",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 250
        )

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(location)

        // Decode
        let decoder = JSONDecoder()
        let decodedLocation = try decoder.decode(TrustedLocation.self, from: data)

        XCTAssertEqual(location.name, decodedLocation.name)
        XCTAssertEqual(location.coordinate.latitude, decodedLocation.coordinate.latitude)
        XCTAssertEqual(location.coordinate.longitude, decodedLocation.coordinate.longitude)
        XCTAssertEqual(location.radius, decodedLocation.radius)
    }
}

// MARK: - Mock Location Manager Delegate

class MockLocationManagerDelegate: LocationManagerDelegate {
    var didLeaveTrustedLocation = false
    var didEnterTrustedLocation = false
    var authorizationStatus: CLAuthorizationStatus?

    func locationManagerDidLeaveTrustedLocation() {
        didLeaveTrustedLocation = true
    }

    func locationManagerDidEnterTrustedLocation() {
        didEnterTrustedLocation = true
    }

    func locationManager(didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
}
