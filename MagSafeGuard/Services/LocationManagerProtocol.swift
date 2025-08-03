//
//  LocationManagerProtocol.swift
//  MagSafe Guard
//
//  Created on 2025-08-01.
//
//  Protocol defining location manager operations.
//  This allows for testability by separating business logic from CLLocationManager.
//

import CoreLocation
import Foundation

/// Protocol defining location-based auto-arm operations
public protocol LocationManagerProtocol: AnyObject {
  /// Delegate for receiving location-based events
  var delegate: LocationManagerDelegate? { get set }

  /// Currently configured trusted locations
  var trustedLocations: [TrustedLocation] { get }

  /// Whether location monitoring is currently active
  var isMonitoring: Bool { get }

  /// Current device location (if available)
  var currentLocation: CLLocation? { get }

  /// Whether the device is currently in a trusted location
  var isInTrustedLocation: Bool { get }

  /// Starts monitoring location for auto-arm functionality
  func startMonitoring()

  /// Stops location monitoring
  func stopMonitoring()

  /// Adds a new trusted location
  /// - Parameter location: The trusted location to add
  func addTrustedLocation(_ location: TrustedLocation)

  /// Removes a trusted location
  /// - Parameter id: The ID of the location to remove
  func removeTrustedLocation(id: UUID)

  /// Updates the list of trusted locations
  /// - Parameter locations: New list of trusted locations
  func updateTrustedLocations(_ locations: [TrustedLocation])

  /// Checks if current location is within any trusted location
  /// - Returns: true if in a trusted location, false otherwise
  func checkIfInTrustedLocation() -> Bool
}

/// Protocol defining Core Location operations
public protocol CLLocationManagerProtocol: AnyObject {
  /// The delegate object to receive location updates
  var delegate: CLLocationManagerDelegate? { get set }

  /// The accuracy of the location data
  var desiredAccuracy: CLLocationAccuracy { get set }

  /// A Boolean value indicating whether the location manager object should pause location updates
  var pausesLocationUpdatesAutomatically: Bool { get set }

  /// The minimum distance (measured in meters) a device must move horizontally before an update event is generated
  var distanceFilter: CLLocationDistance { get set }

  /// Returns the app's authorization status for using location services
  var authorizationStatus: CLAuthorizationStatus { get }

  /// The set of regions currently being monitored
  var monitoredRegions: Set<CLRegion> { get }

  /// Requests permission to use location services whenever the app is running
  func requestAlwaysAuthorization()

  /// Starts the generation of updates that report the user's current location
  func startUpdatingLocation()

  /// Stops the generation of location updates
  func stopUpdatingLocation()

  /// Starts monitoring the specified geographic region
  /// - Parameter region: The region object defining the boundary to monitor
  func startMonitoring(for region: CLRegion)

  /// Stops monitoring the specified geographic region
  /// - Parameter region: The region object currently being monitored
  func stopMonitoring(for region: CLRegion)

  /// Returns a Boolean value indicating whether the device supports region monitoring for the specified region
  /// - Parameter regionClass: The class of the region to test
  /// - Returns: true if the device supports monitoring regions of the specified type, false otherwise
  static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool
}

/// Real implementation wrapping CLLocationManager
public class RealCLLocationManager: CLLocationManagerProtocol {
  private let locationManager: CLLocationManager

  /// Creates a new instance wrapping a real CLLocationManager
  public init() {
    self.locationManager = CLLocationManager()
  }

  /// The delegate object for receiving location updates
  public weak var delegate: CLLocationManagerDelegate? {
    get { locationManager.delegate }
    set { locationManager.delegate = newValue }
  }

  /// The desired accuracy of location data
  public var desiredAccuracy: CLLocationAccuracy {
    get { locationManager.desiredAccuracy }
    set { locationManager.desiredAccuracy = newValue }
  }

  /// Whether location updates should pause automatically
  public var pausesLocationUpdatesAutomatically: Bool {
    get { locationManager.pausesLocationUpdatesAutomatically }
    set { locationManager.pausesLocationUpdatesAutomatically = newValue }
  }

  /// The minimum distance in meters for location updates
  public var distanceFilter: CLLocationDistance {
    get { locationManager.distanceFilter }
    set { locationManager.distanceFilter = newValue }
  }

  /// The current authorization status for location services
  public var authorizationStatus: CLAuthorizationStatus {
    locationManager.authorizationStatus
  }

  /// The set of regions currently being monitored
  public var monitoredRegions: Set<CLRegion> {
    locationManager.monitoredRegions
  }

  /// Requests always authorization for location services
  public func requestAlwaysAuthorization() {
    locationManager.requestAlwaysAuthorization()
  }

  /// Starts updating the user's location
  public func startUpdatingLocation() {
    locationManager.startUpdatingLocation()
  }

  /// Stops updating the user's location
  public func stopUpdatingLocation() {
    locationManager.stopUpdatingLocation()
  }

  /// Starts monitoring the specified region
  public func startMonitoring(for region: CLRegion) {
    locationManager.startMonitoring(for: region)
  }

  /// Stops monitoring the specified region
  public func stopMonitoring(for region: CLRegion) {
    locationManager.stopMonitoring(for: region)
  }

  /// Checks if monitoring is available for the specified region class
  public static func isMonitoringAvailable(for regionClass: AnyClass) -> Bool {
    CLLocationManager.isMonitoringAvailable(for: regionClass)
  }
}

/// Factory for creating location managers
public protocol LocationManagerFactoryProtocol {
  /// Creates a new location manager instance
  /// - Returns: A new location manager instance
  func createLocationManager() -> LocationManagerProtocol

  /// Creates a new Core Location manager instance
  /// - Returns: A new Core Location manager instance
  func createCLLocationManager() -> CLLocationManagerProtocol
}

/// Real factory that creates location manager instances
public class RealLocationManagerFactory: LocationManagerFactoryProtocol {
  /// Creates a new factory instance
  public init() {}

  /// Creates a new real location manager
  /// - Returns: A new LocationManager instance
  public func createLocationManager() -> LocationManagerProtocol {
    return LocationManager(clLocationManager: createCLLocationManager())
  }

  /// Creates a new real Core Location manager
  /// - Returns: A new RealCLLocationManager instance
  public func createCLLocationManager() -> CLLocationManagerProtocol {
    return RealCLLocationManager()
  }
}
