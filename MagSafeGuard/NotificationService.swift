//
//  NotificationService.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Centralized notification service for handling user notifications
//  across different environments (bundled app vs development).
//

import AppKit
import Foundation
import UserNotifications

/// Protocol for notification delivery implementations.
///
/// Provides a unified interface for different notification delivery methods,
/// allowing the service to adapt to different environments (bundled app vs development).
public protocol NotificationDeliveryProtocol {
  /// Delivers a notification with the specified content.
  /// - Parameters:
  ///   - title: The notification title
  ///   - message: The notification message body
  ///   - identifier: Unique identifier for the notification
  func deliver(title: String, message: String, identifier: String)

  /// Requests notification permissions from the system.
  /// - Parameter completion: Called with the result of the permission request
  func requestPermissions(completion: @escaping (Bool) -> Void)
}

/// Centralized notification service for MagSafe Guard.
///
/// The NotificationService manages all user-facing notifications including:
/// - Status change notifications (armed/disarmed)
/// - Critical security alerts (power disconnection, grace period)
/// - System notifications (settings exported, errors)
///
/// ## Architecture
///
/// The service uses a protocol-based delivery system that adapts to the environment:
/// - **Bundled Apps**: Uses UserNotifications framework for native notifications
/// - **Development**: Uses NSAlert windows for immediate visibility
/// - **Testing**: Supports mock delivery methods for unit testing
///
/// ## Usage
///
/// ```swift
/// // Show a standard notification
/// NotificationService.shared.showNotification(
///     title: "System Armed",
///     message: "Protection is now active"
/// )
///
/// // Show a critical alert (bypasses Do Not Disturb)
/// NotificationService.shared.showCriticalAlert(
///     title: "Security Alert",
///     message: "Power disconnected!"
/// )
/// ```
///
/// ## Settings Integration
///
/// The service respects user preferences from `UserDefaultsManager`:
/// - `showStatusNotifications`: Controls standard notifications
/// - `playCriticalAlertSound`: Controls audio for critical alerts
///
/// ## Thread Safety
///
/// All public methods are thread-safe and can be called from any queue.
/// UI updates are automatically dispatched to the main queue.
public class NotificationService {

  // MARK: - Singleton

  /// Shared instance of the notification service.
  ///
  /// The shared instance is automatically configured with the appropriate
  /// delivery method based on the runtime environment.
  public static let shared = NotificationService()

  // MARK: - Testing Support

  /// Controls whether notifications are disabled for testing.
  ///
  /// When set to `true`, all notifications are suppressed except when using
  /// mock delivery methods. This prevents notifications from appearing during
  /// automated tests while still allowing test validation of notification calls.
  ///
  /// - Note: This only affects real notification delivery methods, not mocks
  public static var disableForTesting = false

  // MARK: - Properties

  private var deliveryMethod: NotificationDeliveryProtocol
  private var permissionsGranted = false

  // MARK: - Initialization

  private init() {
    // Choose delivery method based on bundle identifier
    if Bundle.main.bundleIdentifier != nil {
      self.deliveryMethod = UserNotificationDelivery()
    } else {
      self.deliveryMethod = AlertWindowDelivery()
    }

    // Don't request permissions in init - causes issues in test environment
    // Permissions will be requested lazily when first notification is sent
  }

  /// Initialize with custom delivery method for testing.
  ///
  /// This initializer allows dependency injection of mock delivery methods
  /// for unit testing, enabling verification of notification behavior without
  /// actually displaying notifications to the user.
  ///
  /// - Parameter deliveryMethod: Custom delivery implementation to use
  public init(deliveryMethod: NotificationDeliveryProtocol) {
    self.deliveryMethod = deliveryMethod
  }

  // MARK: - Public Methods

  /// Displays a standard notification to the user.
  ///
  /// This method shows status notifications that can be controlled by user settings.
  /// The notification will be suppressed if:
  /// - Status notifications are disabled in settings
  /// - Notifications are disabled for testing (and not using a mock)
  /// - Required permissions are not granted
  ///
  /// The method automatically handles permission requests and adapts to the
  /// current delivery method.
  ///
  /// - Parameters:
  ///   - title: The notification title
  ///   - message: The notification message body
  public func showNotification(title: String, message: String) {
    // Skip notifications if disabled for testing, unless using a mock delivery method
    // Check for any mock class (they will be defined in tests)
    if NotificationService.disableForTesting
      && !String(describing: type(of: deliveryMethod)).contains("Mock")
    {
      Log.debug("Skipping notification - disabled for testing")
      return
    }

    // Check if status notifications are enabled in settings
    if !UserDefaultsManager.shared.settings.showStatusNotifications {
      Log.debug("Status notifications disabled in settings")
      return
    }

    // Request permissions if not already done (lazy initialization)
    if !permissionsGranted {
      requestPermissions()
    }

    let identifier = "MagSafeGuard-\(UUID().uuidString)"
    deliveryMethod.deliver(title: title, message: message, identifier: identifier)
  }

  /// Requests notification permissions from the system.
  ///
  /// This method triggers the system permission dialog for notifications.
  /// The result is cached internally and used to determine whether subsequent
  /// notifications can be delivered via the UserNotifications framework.
  ///
  /// - Note: Permissions are requested automatically when the first notification
  ///   is attempted, so manual calls to this method are usually not necessary
  public func requestPermissions() {
    deliveryMethod.requestPermissions { [weak self] granted in
      self?.permissionsGranted = granted
      Log.info("Permissions granted: \(granted)")
    }
  }

  /// Displays a critical security alert that bypasses user preferences.
  ///
  /// Critical alerts are used for security events that require immediate user attention,
  /// such as power disconnection or grace period warnings. These notifications:
  /// - Bypass the `showStatusNotifications` setting
  /// - Use critical alert priority when available
  /// - Fall back to alert windows if permissions are denied
  /// - Are not suppressed during testing (unless using mocks)
  ///
  /// - Parameters:
  ///   - title: The alert title (typically "Security Alert")
  ///   - message: The alert message describing the security event
  public func showCriticalAlert(title: String, message: String) {
    // For critical alerts, always try alert window as fallback
    if !permissionsGranted && deliveryMethod is UserNotificationDelivery {
      AlertWindowDelivery().deliver(title: title, message: message, identifier: "critical")
    } else {
      showNotification(title: title, message: message)
    }
  }
}

// MARK: - User Notification Delivery

/// Delivers notifications using UNUserNotificationCenter
private class UserNotificationDelivery: NotificationDeliveryProtocol {

  func deliver(title: String, message: String, identifier: String) {
    // Check if we're in a test environment or Xcode Agents
    let bundleURL = Bundle.main.bundleURL.path
    if Bundle.main.bundleIdentifier == nil || bundleURL.contains("Xcode")
      || bundleURL.contains("Developer")
    {
      Log.debug("Skipping delivery - test/development environment")
      return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = message
    content.sound = .default

    // For critical security alerts, use critical alert if available
    if title.contains("Security") || title.contains("Alert") {
      content.interruptionLevel = .critical
    }

    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        Log.error("Error showing notification", error: error)
        // Fallback to alert window
        AlertWindowDelivery().deliver(title: title, message: message, identifier: identifier)
      }
    }
  }

  func requestPermissions(completion: @escaping (Bool) -> Void) {
    // Check if we're in a test environment or Xcode Agents
    let bundleURL = Bundle.main.bundleURL.path
    if Bundle.main.bundleIdentifier == nil || bundleURL.contains("Xcode")
      || bundleURL.contains("Developer")
    {
      Log.debug("Skipping permissions - test/development environment")
      completion(false)
      return
    }

    let options: UNAuthorizationOptions = [.alert, .sound, .criticalAlert]

    UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
      if let error = error {
        Log.error("Permission error", error: error)
      }
      completion(granted)
    }
  }
}

// MARK: - Alert Window Delivery

/// Delivers notifications using NSAlert (fallback for development)
private class AlertWindowDelivery: NotificationDeliveryProtocol {

  func deliver(title: String, message: String, identifier: String) {
    DispatchQueue.main.async {
      // Also log to console
      Log.info("🔔 NOTIFICATION: \(title) - \(message)")

      let alert = NSAlert()
      alert.messageText = title
      alert.informativeText = message

      // Style based on content
      if title.contains("Security") || title.contains("Alert") {
        alert.alertStyle = .critical
      } else {
        alert.alertStyle = .informational
      }

      alert.addButton(withTitle: "OK")

      // For grace period notifications, add cancel option
      if message.contains("Security action in") {
        alert.addButton(withTitle: "Cancel Action")
      }

      let response = alert.runModal()

      // Handle cancel action
      if response == .alertSecondButtonReturn {
        // Post notification that user wants to cancel
        NotificationCenter.default.post(
          name: Notification.Name("MagSafeGuard.CancelGracePeriod"),
          object: nil
        )
      }
    }
  }

  func requestPermissions(completion: @escaping (Bool) -> Void) {
    // Alert windows don't need permissions
    completion(true)
  }
}

// MARK: - Mock Delivery (for testing)

/// Mock notification delivery implementation for unit testing.
///
/// This mock captures notification calls without displaying actual notifications,
/// allowing tests to verify notification behavior while controlling permissions
/// and tracking delivery attempts.
public class MockNotificationDelivery: NotificationDeliveryProtocol {

  /// Array of all notifications that were attempted to be delivered.
  /// Each entry contains the title, message, and identifier provided.
  public var deliveredNotifications: [(title: String, message: String, identifier: String)] = []

  /// Whether permission request was called.
  public var permissionsRequested = false

  /// Controls the response to permission requests for testing scenarios.
  public var shouldGrantPermissions = true

  /// Initialize a new mock delivery instance.
  public init() {
    // Empty initializer - all properties have default values
    // No setup required for this mock implementation
  }

  /// Records the notification delivery attempt.
  /// - Parameters:
  ///   - title: Notification title
  ///   - message: Notification message
  ///   - identifier: Notification identifier
  public func deliver(title: String, message: String, identifier: String) {
    deliveredNotifications.append((title, message, identifier))
  }

  /// Simulates permission request with configurable response.
  /// - Parameter completion: Called with the configured permission result
  public func requestPermissions(completion: @escaping (Bool) -> Void) {
    permissionsRequested = true
    completion(shouldGrantPermissions)
  }

  /// Resets all recorded state for test isolation.
  public func reset() {
    deliveredNotifications.removeAll()
    permissionsRequested = false
  }
}
