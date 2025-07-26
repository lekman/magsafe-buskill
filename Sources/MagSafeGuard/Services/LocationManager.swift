//
//  LocationManager.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Manages location-based auto-arming functionality using CoreLocation
//

import Foundation
import CoreLocation

/// Protocol for location-based auto-arm events
public protocol LocationManagerDelegate: AnyObject {
    /// Called when the device leaves a trusted location
    func locationManagerDidLeaveTrustedLocation()
    /// Called when the device enters a trusted location
    func locationManagerDidEnterTrustedLocation()
    /// Called when location permissions change
    func locationManager(didChangeAuthorization status: CLAuthorizationStatus)
}

/// Represents a trusted location for auto-arm functionality
public struct TrustedLocation: Codable, Equatable {
    /// User-friendly name for the location
    public let name: String
    /// GPS coordinates of the location center
    public let coordinate: CLLocationCoordinate2D
    /// Radius in meters defining the trusted area
    public let radius: CLLocationDistance
    /// Unique identifier for the location
    public let id: UUID
    
    /// Creates a new trusted location
    /// - Parameters:
    ///   - name: User-friendly name
    ///   - coordinate: GPS coordinates
    ///   - radius: Radius in meters (default: 100m)
    public init(name: String, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance = 100.0) {
        self.name = name
        self.coordinate = coordinate
        self.radius = radius
        self.id = UUID()
    }
}

// Make CLLocationCoordinate2D conform to Codable and Equatable
extension CLLocationCoordinate2D: Codable, Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

/// Manages location-based automatic arming of the security system.
///
/// LocationManager monitors the device's location and triggers auto-arm
/// when the device leaves trusted locations. It uses CoreLocation for
/// efficient background monitoring with minimal battery impact.
///
/// ## Features
/// - Geofencing for trusted locations
/// - Background location monitoring
/// - Battery-efficient updates
/// - Permission handling
///
/// ## Usage
/// ```swift
/// let manager = LocationManager()
/// manager.delegate = self
/// manager.addTrustedLocation(TrustedLocation(
///     name: "Home",
///     coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
///     radius: 100
/// ))
/// manager.startMonitoring()
/// ```
public class LocationManager: NSObject {
    
    // MARK: - Properties
    
    /// Delegate for receiving location-based events
    public weak var delegate: LocationManagerDelegate?
    
    /// Currently configured trusted locations
    public private(set) var trustedLocations: [TrustedLocation] = []
    
    /// Whether location monitoring is currently active
    public private(set) var isMonitoring = false
    
    /// Current device location (if available)
    public private(set) var currentLocation: CLLocation?
    
    /// Whether the device is currently in a trusted location
    public private(set) var isInTrustedLocation = false
    
    // Private properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let trustedLocationsKey = "MagSafeGuard.TrustedLocations"
    
    // MARK: - Initialization
    
    /// Initializes the location manager
    public override init() {
        super.init()
        setupLocationManager()
        loadTrustedLocations()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.pausesLocationUpdatesAutomatically = true
        // Background location updates require special entitlements
        // locationManager.allowsBackgroundLocationUpdates = true
        locationManager.distanceFilter = 50 // Update every 50 meters
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring location for auto-arm functionality
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Check authorization status
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            beginLocationMonitoring()
        case .denied, .restricted:
            delegate?.locationManager(didChangeAuthorization: status)
        @unknown default:
            break
        }
    }
    
    /// Stops location monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        locationManager.stopUpdatingLocation()
        
        // Stop monitoring all regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        isMonitoring = false
    }
    
    /// Adds a new trusted location
    /// - Parameter location: The trusted location to add
    public func addTrustedLocation(_ location: TrustedLocation) {
        trustedLocations.append(location)
        saveTrustedLocations()
        
        // Start monitoring this region if we're already monitoring
        if isMonitoring {
            startMonitoringRegion(for: location)
        }
    }
    
    /// Removes a trusted location
    /// - Parameter id: The ID of the location to remove
    public func removeTrustedLocation(id: UUID) {
        guard let index = trustedLocations.firstIndex(where: { $0.id == id }) else { return }
        
        trustedLocations.remove(at: index)
        saveTrustedLocations()
        
        // Stop monitoring this region
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == id.uuidString }) {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    /// Updates the list of trusted locations
    /// - Parameter locations: New list of trusted locations
    public func updateTrustedLocations(_ locations: [TrustedLocation]) {
        // Stop monitoring old regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        trustedLocations = locations
        saveTrustedLocations()
        
        // Start monitoring new regions if monitoring is active
        if isMonitoring {
            for location in trustedLocations {
                startMonitoringRegion(for: location)
            }
        }
    }
    
    /// Checks if current location is within any trusted location
    /// - Returns: true if in a trusted location, false otherwise
    public func checkIfInTrustedLocation() -> Bool {
        guard let currentLocation = currentLocation else { return false }
        
        for trustedLocation in trustedLocations {
            let trustedCoordinate = CLLocation(
                latitude: trustedLocation.coordinate.latitude,
                longitude: trustedLocation.coordinate.longitude
            )
            
            if currentLocation.distance(from: trustedCoordinate) <= trustedLocation.radius {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func beginLocationMonitoring() {
        isMonitoring = true
        locationManager.startUpdatingLocation()
        
        // Set up geofences for all trusted locations
        for location in trustedLocations {
            startMonitoringRegion(for: location)
        }
    }
    
    private func startMonitoringRegion(for location: TrustedLocation) {
        // Check if region monitoring is available
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("[LocationManager] Region monitoring not available")
            return
        }
        
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: location.radius,
            identifier: location.id.uuidString
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    private func loadTrustedLocations() {
        if let data = userDefaults.data(forKey: trustedLocationsKey),
           let locations = try? JSONDecoder().decode([TrustedLocation].self, from: data) {
            trustedLocations = locations
        }
    }
    
    private func saveTrustedLocations() {
        if let data = try? JSONEncoder().encode(trustedLocations) {
            userDefaults.set(data, forKey: trustedLocationsKey)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        // Check if we're in a trusted location
        let wasInTrustedLocation = isInTrustedLocation
        isInTrustedLocation = checkIfInTrustedLocation()
        
        // Notify delegate if status changed
        if wasInTrustedLocation && !isInTrustedLocation {
            delegate?.locationManagerDidLeaveTrustedLocation()
        } else if !wasInTrustedLocation && isInTrustedLocation {
            delegate?.locationManagerDidEnterTrustedLocation()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("[LocationManager] Entered region: \(region.identifier)")
        isInTrustedLocation = true
        delegate?.locationManagerDidEnterTrustedLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("[LocationManager] Exited region: \(region.identifier)")
        
        // Check if we're still in any other trusted location
        isInTrustedLocation = checkIfInTrustedLocation()
        
        if !isInTrustedLocation {
            delegate?.locationManagerDidLeaveTrustedLocation()
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        delegate?.locationManager(didChangeAuthorization: status)
        
        // Start monitoring if we just got permission
        if status == .authorizedAlways {
            if !isMonitoring {
                beginLocationMonitoring()
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Location error: \(error.localizedDescription)")
    }
}