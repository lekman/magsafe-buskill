//
//  PowerMonitorCore.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This file contains the testable core logic extracted from PowerMonitorService
//  to enable better unit testing without IOKit dependencies.
//

import Foundation
import IOKit.ps

/// Core logic for power monitoring that can be tested without IOKit dependencies.
///
/// PowerMonitorCore provides the testable business logic for power state monitoring,
/// extracted from IOKit dependencies to enable comprehensive unit testing. This class
/// handles parsing of power source information and state change detection.
///
/// ## Architecture
///
/// The core separates concerns between:
/// - **Data Processing**: Parsing IOKit power source dictionaries
/// - **State Management**: Tracking power state changes over time
/// - **Testing Support**: Providing testable interfaces without system dependencies
///
/// ## Usage
///
/// ```swift
/// let core = PowerMonitorCore()
/// let powerInfo = core.processPowerSourceInfo(sources)
/// if core.hasPowerStateChanged(newInfo: powerInfo) {
///     // Handle power state change
/// }
/// ```
///
/// ## Thread Safety
///
/// This class is not thread-safe. Callers should ensure synchronized access
/// or use it from a single queue (as PowerMonitorService does).
public class PowerMonitorCore {

  // MARK: - Types

  /// Comprehensive power state information from system power sources.
  ///
  /// Contains all relevant power metrics including connection state, battery status,
  /// and charging information. Used to track power changes over time and provide
  /// detailed information for security decisions.
  public struct PowerInfo: Equatable {
    /// Current power connection state (connected/disconnected)
    public let state: PowerState
    /// Battery charge level as percentage (0-100), nil if no battery
    public let batteryLevel: Int?
    /// Whether the battery is currently charging
    public let isCharging: Bool
    /// Power adapter wattage if available
    public let adapterWattage: Int?
    /// Timestamp when this information was captured
    public let timestamp: Date

    /// Initialize power information with all available metrics.
    /// - Parameters:
    ///   - state: Power connection state
    ///   - batteryLevel: Battery percentage (0-100) or nil
    ///   - isCharging: Whether battery is charging
    ///   - adapterWattage: Adapter power rating in watts
    ///   - timestamp: When information was captured
    public init(
      state: PowerState, batteryLevel: Int?, isCharging: Bool, adapterWattage: Int?, timestamp: Date
    ) {
      self.state = state
      self.batteryLevel = batteryLevel
      self.isCharging = isCharging
      self.adapterWattage = adapterWattage
      self.timestamp = timestamp
    }
  }

  /// Power adapter connection state.
  ///
  /// Represents whether the system is running on external power (connected)
  /// or battery power (disconnected). This is the primary signal used for
  /// security monitoring and triggering protective actions.
  public enum PowerState: String, Equatable {
    /// External power adapter is connected
    case connected
    /// Running on battery power (adapter disconnected)
    case disconnected

    /// Human-readable description of the power state.
    public var description: String {
      switch self {
      case .connected:
        return "Power adapter connected"
      case .disconnected:
        return "Power adapter disconnected"
      }
    }
  }

  // MARK: - Properties

  /// Most recently processed power information.
  ///
  /// Updated each time `processPowerSourceInfo` is called with valid data.
  /// Used for state change detection and external queries.
  public private(set) var currentPowerInfo: PowerInfo?

  /// Interval between power state checks in seconds.
  ///
  /// Determines how frequently the power monitor should check for changes.
  /// Shorter intervals provide faster detection but use more CPU.
  public let pollingInterval: TimeInterval

  // MARK: - Initialization

  /// Initialize the power monitor core with specified polling interval.
  /// - Parameter pollingInterval: How often to check power state (default: 1.0 second)
  public init(pollingInterval: TimeInterval = 1.0) {
    self.pollingInterval = pollingInterval
  }

  // MARK: - Public Methods

  /// Process power source information from IOKit into structured data.
  ///
  /// Parses the raw power source dictionaries from IOPSCopyPowerSourcesInfo
  /// and extracts relevant power metrics. Handles multiple power sources
  /// (internal battery, external adapter) and consolidates information.
  ///
  /// - Parameter sources: Array of power source dictionaries from IOKit
  /// - Returns: Structured power information, or nil if parsing fails
  public func processPowerSourceInfo(_ sources: [[String: Any]]) -> PowerInfo? {
    var state: PowerState = .disconnected
    var batteryLevel: Int?
    var isCharging = false
    var adapterWattage: Int?

    for sourceDict in sources {
      // Check power state
      if let powerSourceState = sourceDict["Power Source State"] as? String {
        state = (powerSourceState == "AC Power") ? .connected : .disconnected
      }

      // Get battery level
      if let currentCapacity = sourceDict["Current Capacity"] as? Int,
        let maxCapacity = sourceDict["Max Capacity"] as? Int,
        maxCapacity > 0 {
        batteryLevel = Int((Double(currentCapacity) / Double(maxCapacity)) * 100)
      }

      // Check if charging
      if let chargingFlag = sourceDict["Is Charging"] as? Bool {
        isCharging = chargingFlag
      }

      // Get adapter wattage if available
      if let adapterInfo = sourceDict["AdapterInfo"] as? Int {
        adapterWattage = adapterInfo
      } else if let adapterDetails = sourceDict["AdapterDetails"] as? [String: Any],
        let watts = adapterDetails["Watts"] as? Int {
        adapterWattage = watts
      }
    }

    return PowerInfo(
      state: state,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      adapterWattage: adapterWattage,
      timestamp: Date()
    )
  }

  /// Determine if the power state has changed since last check.
  ///
  /// Compares the new power information against the previously stored state
  /// to detect connection/disconnection events. Updates internal state
  /// regardless of whether a change occurred.
  ///
  /// - Parameter newInfo: Newly captured power information
  /// - Returns: True if power connection state changed, false otherwise
  public func hasPowerStateChanged(newInfo: PowerInfo) -> Bool {
    guard let currentInfo = currentPowerInfo else {
      // First reading
      currentPowerInfo = newInfo
      return true
    }

    if currentInfo.state != newInfo.state {
      currentPowerInfo = newInfo
      return true
    }

    // Update current info even if state didn't change
    currentPowerInfo = newInfo
    return false
  }

  /// Get current battery level in Objective-C compatible format.
  ///
  /// Provides battery charge percentage for Objective-C code that cannot
  /// handle Swift optionals. Uses -1 to indicate unavailable data.
  ///
  /// - Returns: Battery level (0-100) or -1 if unavailable
  @objc public func getBatteryLevel() -> Int {
    return currentPowerInfo?.batteryLevel ?? -1
  }

  /// Get current power connection status in Objective-C compatible format.
  ///
  /// Provides boolean power state for Objective-C code that needs simple
  /// connected/disconnected status without optionals.
  ///
  /// - Returns: True if external power is connected, false otherwise
  @objc public func isPowerConnected() -> Bool {
    return currentPowerInfo?.state == .connected
  }

  /// Reset internal state for testing purposes.
  ///
  /// Clears the current power information, allowing tests to start
  /// with a clean state and verify initial behavior.
  ///
  /// - Note: This method is intended for testing only
  public func reset() {
    currentPowerInfo = nil
  }
}

// These constants are defined in IOKit.ps and used as CFString
// We'll use the string values directly in our code since they're CFString constants
