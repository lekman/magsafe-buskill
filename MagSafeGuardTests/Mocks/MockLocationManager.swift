//
//  MockLocationManager.swift
//  MagSafe Guard
//
//  Created on 2025-08-01.
//
//  Mock implementation of location manager for testing.
//

import CoreLocation
import Foundation

@testable import MagSafeGuard

/// Mock implementation of location manager for testing
public class MockLocationManager: LocationManagerProtocol {

  // MARK: - Properties

  /// Delegate for location manager events
  public weak var delegate: LocationManagerDelegate?

  /// List of trusted locations for testing
  public private(set) var trustedLocations: [TrustedLocation] = []

  /// Whether location monitoring is active
  public private(set) var isMonitoring = false

  /// Current device location for testing
  public private(set) var currentLocation: CLLocation?

  /// Whether device is in a trusted location
  public private(set) var isInTrustedLocation = false

  // MARK: - Test Control

  /// Set the current location for testing
  public var mockCurrentLocation: CLLocation? {
    didSet {
      currentLocation = mockCurrentLocation
    }
  }

  /// Control whether checkIfInTrustedLocation returns true
  public var mockIsInTrustedLocation = false

  // MARK: - Call Tracking

  /// Tracks if startMonitoring was called
  public var startMonitoringCalled = false

  /// Tracks if stopMonitoring was called
  public var stopMonitoringCalled = false

  /// Tracks if addTrustedLocation was called
  public var addTrustedLocationCalled = false

  /// Tracks if removeTrustedLocation was called
  public var removeTrustedLocationCalled = false

  /// Tracks if updateTrustedLocations was called
  public var updateTrustedLocationsCalled = false

  /// Tracks if checkIfInTrustedLocation was called
  public var checkIfInTrustedLocationCalled = false

  /// Last location passed to addTrustedLocation
  public var lastAddedLocation: TrustedLocation?

  /// Last ID passed to removeTrustedLocation
  public var lastRemovedLocationId: UUID?

  /// Last locations passed to updateTrustedLocations
  public var lastUpdatedLocations: [TrustedLocation]?

  // MARK: - Initialization

  /// Creates a new mock location manager
  public init() {}

  // MARK: - LocationManagerProtocol

  /// Starts location monitoring
  public func startMonitoring() {
    startMonitoringCalled = true
    isMonitoring = true
  }

  /// Stops location monitoring
  public func stopMonitoring() {
    stopMonitoringCalled = true
    isMonitoring = false
  }

  /// Adds a trusted location
  public func addTrustedLocation(_ location: TrustedLocation) {
    addTrustedLocationCalled = true
    lastAddedLocation = location
    trustedLocations.append(location)
  }

  /// Removes a trusted location by ID
  public func removeTrustedLocation(id: UUID) {
    removeTrustedLocationCalled = true
    lastRemovedLocationId = id
    trustedLocations.removeAll { $0.id == id }
  }

  /// Updates the list of trusted locations
  public func updateTrustedLocations(_ locations: [TrustedLocation]) {
    updateTrustedLocationsCalled = true
    lastUpdatedLocations = locations
    trustedLocations = locations
  }

  /// Checks if current location is within any trusted location
  public func checkIfInTrustedLocation() -> Bool {
    checkIfInTrustedLocationCalled = true
    isInTrustedLocation = mockIsInTrustedLocation
    return mockIsInTrustedLocation
  }

  // MARK: - Test Helpers

  /// Reset all tracking variables
  public func reset() {
    trustedLocations = []
    isMonitoring = false
    currentLocation = nil
    isInTrustedLocation = false

    mockCurrentLocation = nil
    mockIsInTrustedLocation = false

    startMonitoringCalled = false
    stopMonitoringCalled = false
    addTrustedLocationCalled = false
    removeTrustedLocationCalled = false
    updateTrustedLocationsCalled = false
    checkIfInTrustedLocationCalled = false

    lastAddedLocation = nil
    lastRemovedLocationId = nil
    lastUpdatedLocations = nil
  }

  /// Simulate entering a trusted location
  public func simulateEnterTrustedLocation() {
    isInTrustedLocation = true
    delegate?.locationManagerDidEnterTrustedLocation()
  }

  /// Simulate leaving a trusted location
  public func simulateLeaveTrustedLocation() {
    isInTrustedLocation = false
    delegate?.locationManagerDidLeaveTrustedLocation()
  }

  /// Simulate authorization change
  public func simulateAuthorizationChange(_ status: CLAuthorizationStatus) {
    delegate?.locationManager(didChangeAuthorization: status)
  }
}

/// Mock implementation of Core Location manager for testing
public class MockCLLocationManager: CLLocationManagerProtocol {

  // MARK: - Properties

  /// Delegate for Core Location events
  public weak var delegate: CLLocationManagerDelegate?

  /// Desired accuracy for location updates
  public var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters

  /// Whether to pause location updates automatically
  public var pausesLocationUpdatesAutomatically = true

  /// Minimum distance filter for location updates
  public var distanceFilter: CLLocationDistance = 50

  /// Set of regions being monitored
  public var monitoredRegions = Set<CLRegion>()

  // MARK: - Test Control

  /// Control the authorization status returned
  public var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined

  /// Control whether monitoring is available
  public static var mockIsMonitoringAvailable = true

  /// Returns the mocked authorization status
  public var authorizationStatus: CLAuthorizationStatus {
    return mockAuthorizationStatus
  }

  // MARK: - Call Tracking

  /// Tracks if requestAlwaysAuthorization was called
  public var requestAlwaysAuthorizationCalled = false

  /// Tracks if startUpdatingLocation was called
  public var startUpdatingLocationCalled = false

  /// Tracks if stopUpdatingLocation was called
  public var stopUpdatingLocationCalled = false

  /// Tracks if startMonitoring was called
  public var startMonitoringCalled = false

  /// Tracks if stopMonitoring was called
  public var stopMonitoringCalled = false

  /// Last region passed to startMonitoring
  public var lastStartedMonitoringRegion: CLRegion?

  /// Last region passed to stopMonitoring
  public var lastStoppedMonitoringRegion: CLRegion?

  // MARK: - Initialization

  /// Creates a new mock Core Location manager
  public init() {}

  // MARK: - CLLocationManagerProtocol

  /// Requests always authorization for location services
  public func requestAlwaysAuthorization() {
    requestAlwaysAuthorizationCalled = true
    // Simulate immediate authorization change
    mockAuthorizationStatus = .authorizedAlways
    // Note: We can't call the delegate method directly since we're not a real CLLocationManager
    // Tests should check the mockAuthorizationStatus directly or use simulateAuthorizationChange
  }

  /// Starts updating location
  public func startUpdatingLocation() {
    startUpdatingLocationCalled = true
  }

  /// Stops updating location
  public func stopUpdatingLocation() {
    stopUpdatingLocationCalled = true
  }

  /// Starts monitoring the specified region
  public func startMonitoring(for region: CLRegion) {
    startMonitoringCalled = true
    lastStartedMonitoringRegion = region
    monitoredRegions.insert(region)
  }

  /// Stops monitoring the specified region
  public func stopMonitoring(for region: CLRegion) {
    stopMonitoringCalled = true
    lastStoppedMonitoringRegion = region
    monitoredRegions.remove(region)
  }

  /// Checks if monitoring is available for the specified region class
  public static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
    return mockIsMonitoringAvailable
  }

  // MARK: - Test Helpers

  /// Reset all tracking variables
  public func reset() {
    desiredAccuracy = kCLLocationAccuracyHundredMeters
    pausesLocationUpdatesAutomatically = true
    distanceFilter = 50
    monitoredRegions.removeAll()

    mockAuthorizationStatus = .notDetermined

    requestAlwaysAuthorizationCalled = false
    startUpdatingLocationCalled = false
    stopUpdatingLocationCalled = false
    startMonitoringCalled = false
    stopMonitoringCalled = false

    lastStartedMonitoringRegion = nil
    lastStoppedMonitoringRegion = nil
  }

  /// Simulate location update
  public func simulateLocationUpdate(_ location: CLLocation) {
    if let delegate = delegate as? CLLocationManagerDelegate {
      delegate.locationManager?(CLLocationManager(), didUpdateLocations: [location])
    }
  }

  /// Simulate entering region
  public func simulateEnterRegion(_ region: CLRegion) {
    if let delegate = delegate as? CLLocationManagerDelegate {
      delegate.locationManager?(CLLocationManager(), didEnterRegion: region)
    }
  }

  /// Simulate exiting region
  public func simulateExitRegion(_ region: CLRegion) {
    if let delegate = delegate as? CLLocationManagerDelegate {
      delegate.locationManager?(CLLocationManager(), didExitRegion: region)
    }
  }
}

/// Mock factory for testing
public class MockLocationManagerFactory: LocationManagerFactoryProtocol {

  /// The mock location manager to return
  public let mockLocationManager: MockLocationManager

  /// The mock Core Location manager to return
  public let mockCLLocationManager: MockCLLocationManager

  /// Track creation calls
  public var createLocationManagerCalled = false

  /// Track Core Location manager creation calls
  public var createCLLocationManagerCalled = false

  /// Creates a new mock factory with the specified managers
  public init(
    mockLocationManager: MockLocationManager = MockLocationManager(),
    mockCLLocationManager: MockCLLocationManager = MockCLLocationManager()
  ) {
    self.mockLocationManager = mockLocationManager
    self.mockCLLocationManager = mockCLLocationManager
  }

  /// Creates and returns the mock location manager
  public func createLocationManager() -> LocationManagerProtocol {
    createLocationManagerCalled = true
    return mockLocationManager
  }

  /// Creates and returns the mock Core Location manager
  public func createCLLocationManager() -> CLLocationManagerProtocol {
    createCLLocationManagerCalled = true
    return mockCLLocationManager
  }
}
