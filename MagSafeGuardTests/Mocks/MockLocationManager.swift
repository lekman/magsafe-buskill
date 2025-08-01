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

  public weak var delegate: LocationManagerDelegate?
  public private(set) var trustedLocations: [TrustedLocation] = []
  public private(set) var isMonitoring = false
  public private(set) var currentLocation: CLLocation?
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

  public var startMonitoringCalled = false
  public var stopMonitoringCalled = false
  public var addTrustedLocationCalled = false
  public var removeTrustedLocationCalled = false
  public var updateTrustedLocationsCalled = false
  public var checkIfInTrustedLocationCalled = false

  public var lastAddedLocation: TrustedLocation?
  public var lastRemovedLocationId: UUID?
  public var lastUpdatedLocations: [TrustedLocation]?

  // MARK: - Initialization

  public init() {}

  // MARK: - LocationManagerProtocol

  public func startMonitoring() {
    startMonitoringCalled = true
    isMonitoring = true
  }

  public func stopMonitoring() {
    stopMonitoringCalled = true
    isMonitoring = false
  }

  public func addTrustedLocation(_ location: TrustedLocation) {
    addTrustedLocationCalled = true
    lastAddedLocation = location
    trustedLocations.append(location)
  }

  public func removeTrustedLocation(id: UUID) {
    removeTrustedLocationCalled = true
    lastRemovedLocationId = id
    trustedLocations.removeAll { $0.id == id }
  }

  public func updateTrustedLocations(_ locations: [TrustedLocation]) {
    updateTrustedLocationsCalled = true
    lastUpdatedLocations = locations
    trustedLocations = locations
  }

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

  public weak var delegate: CLLocationManagerDelegate?
  public var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
  public var pausesLocationUpdatesAutomatically = true
  public var distanceFilter: CLLocationDistance = 50
  public var monitoredRegions = Set<CLRegion>()

  // MARK: - Test Control

  /// Control the authorization status returned
  public var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined

  /// Control whether monitoring is available
  public static var mockIsMonitoringAvailable = true

  public var authorizationStatus: CLAuthorizationStatus {
    return mockAuthorizationStatus
  }

  // MARK: - Call Tracking

  public var requestAlwaysAuthorizationCalled = false
  public var startUpdatingLocationCalled = false
  public var stopUpdatingLocationCalled = false
  public var startMonitoringCalled = false
  public var stopMonitoringCalled = false

  public var lastStartedMonitoringRegion: CLRegion?
  public var lastStoppedMonitoringRegion: CLRegion?

  // MARK: - Initialization

  public init() {}

  // MARK: - CLLocationManagerProtocol

  public func requestAlwaysAuthorization() {
    requestAlwaysAuthorizationCalled = true
    // Simulate immediate authorization change
    mockAuthorizationStatus = .authorizedAlways
    // Note: We can't call the delegate method directly since we're not a real CLLocationManager
    // Tests should check the mockAuthorizationStatus directly or use simulateAuthorizationChange
  }

  public func startUpdatingLocation() {
    startUpdatingLocationCalled = true
  }

  public func stopUpdatingLocation() {
    stopUpdatingLocationCalled = true
  }

  public func startMonitoring(for region: CLRegion) {
    startMonitoringCalled = true
    lastStartedMonitoringRegion = region
    monitoredRegions.insert(region)
  }

  public func stopMonitoring(for region: CLRegion) {
    stopMonitoringCalled = true
    lastStoppedMonitoringRegion = region
    monitoredRegions.remove(region)
  }

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
  public var createCLLocationManagerCalled = false

  public init(
    mockLocationManager: MockLocationManager = MockLocationManager(),
    mockCLLocationManager: MockCLLocationManager = MockCLLocationManager()
  ) {
    self.mockLocationManager = mockLocationManager
    self.mockCLLocationManager = mockCLLocationManager
  }

  public func createLocationManager() -> LocationManagerProtocol {
    createLocationManagerCalled = true
    return mockLocationManager
  }

  public func createCLLocationManager() -> CLLocationManagerProtocol {
    createCLLocationManagerCalled = true
    return mockCLLocationManager
  }
}
