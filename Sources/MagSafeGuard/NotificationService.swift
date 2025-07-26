//
//  NotificationService.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Centralized notification service for handling user notifications
//  across different environments (bundled app vs development).
//

import Foundation
import UserNotifications
import AppKit

/// Protocol for notification delivery
public protocol NotificationDeliveryProtocol {
    func deliver(title: String, message: String, identifier: String)
    func requestPermissions(completion: @escaping (Bool) -> Void)
}

/// Main notification service
public class NotificationService {
    
    // MARK: - Singleton
    
    public static let shared = NotificationService()
    
    // MARK: - Testing Support
    
    /// Set to true to disable all notifications (for testing)
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
    
    /// Initialize with custom delivery method (for testing)
    public init(deliveryMethod: NotificationDeliveryProtocol) {
        self.deliveryMethod = deliveryMethod
    }
    
    // MARK: - Public Methods
    
    /// Shows a notification with the given title and message
    public func showNotification(title: String, message: String) {
        // Skip notifications if disabled for testing, unless using a mock delivery method
        // Check for any mock class (they will be defined in tests)
        if NotificationService.disableForTesting && !String(describing: type(of: deliveryMethod)).contains("Mock") {
            print("[NotificationService] Skipping notification - disabled for testing")
            return
        }
        
        // Request permissions if not already done (lazy initialization)
        if !permissionsGranted {
            requestPermissions()
        }
        
        let identifier = "MagSafeGuard-\(UUID().uuidString)"
        deliveryMethod.deliver(title: title, message: message, identifier: identifier)
    }
    
    /// Requests notification permissions
    public func requestPermissions() {
        deliveryMethod.requestPermissions { [weak self] granted in
            self?.permissionsGranted = granted
            print("[NotificationService] Permissions granted: \(granted)")
        }
    }
    
    /// Shows a critical alert (always tries to show regardless of permissions)
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
        // Check if we're in a test environment
        guard Bundle.main.bundleIdentifier != nil else {
            print("[UserNotificationDelivery] Skipping delivery - test environment")
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
                print("[UserNotificationDelivery] Error showing notification: \(error)")
                // Fallback to alert window
                AlertWindowDelivery().deliver(title: title, message: message, identifier: identifier)
            }
        }
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        // Check if we're in a test environment
        guard Bundle.main.bundleIdentifier != nil else {
            print("[UserNotificationDelivery] Skipping permissions - test environment")
            completion(false)
            return
        }
        
        let options: UNAuthorizationOptions = [.alert, .sound, .criticalAlert]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("[UserNotificationDelivery] Permission error: \(error)")
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
            print("🔔 NOTIFICATION: \(title) - \(message)")
            
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

/// Mock notification delivery for unit tests
public class MockNotificationDelivery: NotificationDeliveryProtocol {
    
    public var deliveredNotifications: [(title: String, message: String, identifier: String)] = []
    public var permissionsRequested = false
    public var shouldGrantPermissions = true
    
    public init() {}
    
    public func deliver(title: String, message: String, identifier: String) {
        deliveredNotifications.append((title, message, identifier))
    }
    
    public func requestPermissions(completion: @escaping (Bool) -> Void) {
        permissionsRequested = true
        completion(shouldGrantPermissions)
    }
    
    public func reset() {
        deliveredNotifications.removeAll()
        permissionsRequested = false
    }
}