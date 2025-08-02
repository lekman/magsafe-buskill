//
//  LocationManagerTests.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Tests for location-based auto-arm functionality
//

import CoreLocation
import XCTest

@testable import MagSafeGuard

final class LocationManagerTests: XCTestCase {

  var locationManager: LocationManager!
  var mockCLLocationManager: MockCLLocationManager!
  var mockDelegate: MockLocationManagerDelegate!

  override func setUpWithError() throws {
    try super.setUpWithError()

    // Clear any stored locations
    UserDefaults.standard.removeObject(forKey: "MagSafeGuard.TrustedLocations")

    // Create mock Core Location manager
    mockCLLocationManager = MockCLLocationManager()

    // Create location manager with mock
    locationManager = LocationManager(clLocationManager: mockCLLocationManager)

    // Create and set mock delegate
    mockDelegate = MockLocationManagerDelegate()
    locationManager.delegate = mockDelegate
  }

  override func tearDown() {
    locationManager?.stopMonitoring()
    locationManager = nil
    mockCLLocationManager = nil
    mockDelegate = nil
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
      TrustedLocation(
        name: "Home", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        radius: 100),
      TrustedLocation(
        name: "Office", coordinate: CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811),
        radius: 150)
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
    let location1 = TrustedLocation(
      name: "Home", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      radius: 100)
    let location2 = TrustedLocation(
      name: "Office", coordinate: CLLocationCoordinate2D(latitude: 37.3352, longitude: -121.8811),
      radius: 150)

    locationManager.addTrustedLocation(location1)
    locationManager.addTrustedLocation(location2)

    // Create new manager with fresh mock to test loading
    let newMockCLLocationManager = MockCLLocationManager()
    let newManager = LocationManager(clLocationManager: newMockCLLocationManager)

    XCTAssertEqual(newManager.trustedLocations.count, 2)
    XCTAssertTrue(newManager.trustedLocations.contains { $0.name == "Home" })
    XCTAssertTrue(newManager.trustedLocations.contains { $0.name == "Office" })
  }

  // MARK: - Location Monitoring Tests

  func testStartMonitoringRequestsAuthorizationWhenNotDetermined() {
    // Setup
    mockCLLocationManager.mockAuthorizationStatus = .notDetermined

    // Act
    locationManager.startMonitoring()

    // Assert
    XCTAssertTrue(mockCLLocationManager.requestAlwaysAuthorizationCalled)
  }

  func testStartMonitoringBeginsLocationUpdatesWhenAuthorized() {
    // Setup
    mockCLLocationManager.mockAuthorizationStatus = .authorizedAlways

    // Act
    locationManager.startMonitoring()

    // Assert
    XCTAssertTrue(mockCLLocationManager.startUpdatingLocationCalled)
    XCTAssertTrue(locationManager.isMonitoring)
  }

  func testStopMonitoringStopsLocationUpdates() {
    // Setup
    mockCLLocationManager.mockAuthorizationStatus = .authorizedAlways
    locationManager.startMonitoring()

    // Act
    locationManager.stopMonitoring()

    // Assert
    XCTAssertTrue(mockCLLocationManager.stopUpdatingLocationCalled)
    XCTAssertFalse(locationManager.isMonitoring)
  }

  // MARK: - Region Monitoring Tests

  func testAddTrustedLocationStartsMonitoringRegion() {
    // Setup
    mockCLLocationManager.mockAuthorizationStatus = .authorizedAlways
    locationManager.startMonitoring()

    let location = TrustedLocation(
      name: "Test Location",
      coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      radius: 100
    )

    // Act
    locationManager.addTrustedLocation(location)

    // Assert
    XCTAssertTrue(mockCLLocationManager.startMonitoringCalled)
    XCTAssertNotNil(mockCLLocationManager.lastStartedMonitoringRegion)
    XCTAssertEqual(
      mockCLLocationManager.lastStartedMonitoringRegion?.identifier, location.id.uuidString)
  }

  // MARK: - Delegate Tests

  func testLocationUpdateTriggersEnterTrustedLocationDelegate() {
    // Setup
    let location = TrustedLocation(
      name: "Test Location",
      coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      radius: 100
    )
    locationManager.addTrustedLocation(location)

    // Create a location inside the trusted location
    let currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)

    // Act - Simulate location update
    mockCLLocationManager.simulateLocationUpdate(currentLocation)

    // Assert
    XCTAssertTrue(locationManager.isInTrustedLocation)
    XCTAssertTrue(mockDelegate.didEnterTrustedLocation)
  }

  func testLocationUpdateTriggersLeaveTrustedLocationDelegate() {
    // Setup
    let location = TrustedLocation(
      name: "Test Location",
      coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      radius: 100
    )
    locationManager.addTrustedLocation(location)

    // First, simulate being in trusted location
    let insideLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
    mockCLLocationManager.simulateLocationUpdate(insideLocation)

    // Reset delegate
    mockDelegate.didLeaveTrustedLocation = false

    // Act - Simulate moving outside trusted location
    let outsideLocation = CLLocation(latitude: 38.0, longitude: -122.5)
    mockCLLocationManager.simulateLocationUpdate(outsideLocation)

    // Assert
    XCTAssertFalse(locationManager.isInTrustedLocation)
    XCTAssertTrue(mockDelegate.didLeaveTrustedLocation)
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
