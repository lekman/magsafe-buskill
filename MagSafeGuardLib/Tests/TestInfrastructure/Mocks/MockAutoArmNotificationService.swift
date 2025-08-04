//
//  MockAutoArmNotificationService.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of AutoArmNotificationService for testing.
//  Provides controllable notification behavior for unit tests.
//

import Foundation
@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain

/// Mock implementation of AutoArmNotificationService for testing.
/// Allows full control over notification behavior in tests.
public actor MockAutoArmNotificationService: AutoArmNotificationService {

    // MARK: - Properties

    /// Track method calls
    public private(set) var showAutoArmNotificationCalls = 0
    public private(set) var showAutoArmDisabledNotificationCalls = 0
    public private(set) var showAutoArmFailedNotificationCalls = 0

    /// Track notification parameters
    public private(set) var lastAutoArmTrigger: AutoArmTrigger?
    public private(set) var lastDisabledUntil: Date?
    public private(set) var lastFailureError: Error?

    /// Notification history
    public private(set) var notificationHistory: [NotificationRecord] = []

    /// Delay for notifications
    public var notificationDelay: TimeInterval = 0

    /// Whether notifications should fail
    public var shouldFailNotifications = false

    // MARK: - Types

    /// Record of a notification
    public struct NotificationRecord: Equatable {
        public let type: NotificationType
        public let timestamp: Date

        public enum NotificationType: Equatable {
            case autoArm(trigger: AutoArmTrigger)
            case disabled(until: Date)
            case failed(error: String)
        }
    }

    // MARK: - Initialization

    /// Initialize mock service
    public init() {}

    // MARK: - Configuration Methods

    /// Reset all mock state
    public func reset() {
        showAutoArmNotificationCalls = 0
        showAutoArmDisabledNotificationCalls = 0
        showAutoArmFailedNotificationCalls = 0
        lastAutoArmTrigger = nil
        lastDisabledUntil = nil
        lastFailureError = nil
        notificationHistory = []
        notificationDelay = 0
        shouldFailNotifications = false
    }

    // MARK: - AutoArmNotificationService Implementation

    public func showAutoArmNotification(trigger: AutoArmTrigger) async {
        showAutoArmNotificationCalls += 1
        lastAutoArmTrigger = trigger

        if notificationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(notificationDelay * 1_000_000_000))
        }

        if !shouldFailNotifications {
            notificationHistory.append(NotificationRecord(
                type: .autoArm(trigger: trigger),
                timestamp: Date()
            ))
        }
    }

    public func showAutoArmDisabledNotification(until: Date) async {
        showAutoArmDisabledNotificationCalls += 1
        lastDisabledUntil = until

        if notificationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(notificationDelay * 1_000_000_000))
        }

        if !shouldFailNotifications {
            notificationHistory.append(NotificationRecord(
                type: .disabled(until: until),
                timestamp: Date()
            ))
        }
    }

    public func showAutoArmFailedNotification(error: Error) async {
        showAutoArmFailedNotificationCalls += 1
        lastFailureError = error

        if notificationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(notificationDelay * 1_000_000_000))
        }

        if !shouldFailNotifications {
            notificationHistory.append(NotificationRecord(
                type: .failed(error: error.localizedDescription),
                timestamp: Date()
            ))
        }
    }
}

// MARK: - Test Helpers

extension MockAutoArmNotificationService {

    /// Verify notification was shown for trigger
    /// - Parameter trigger: Expected trigger
    /// - Returns: True if notification was shown
    public func verifyNotificationShown(for trigger: AutoArmTrigger) -> Bool {
        notificationHistory.contains { record in
            if case .autoArm(let recordTrigger) = record.type {
                return recordTrigger == trigger
            }
            return false
        }
    }

    /// Get total notification count
    /// - Returns: Total number of notifications shown
    public func getTotalNotificationCount() -> Int {
        notificationHistory.count
    }

    /// Get notifications of specific type
    /// - Parameter type: Type to filter by
    /// - Returns: Matching notifications
    public func getNotifications(ofType type: NotificationRecord.NotificationType) -> [NotificationRecord] {
        notificationHistory.filter { record in
            switch (record.type, type) {
            case (.autoArm(let trigger1), .autoArm(let trigger2)):
                return trigger1 == trigger2
            case (.disabled(let date1), .disabled(let date2)):
                return date1 == date2
            case (.failed(let error1), .failed(let error2)):
                return error1 == error2
            default:
                return false
            }
        }
    }

    /// Verify no notifications were shown
    /// - Returns: True if no notifications
    public func verifyNoNotifications() -> Bool {
        notificationHistory.isEmpty
    }

    /// Get time since last notification
    /// - Returns: Time interval, or nil if no notifications
    public func timeSinceLastNotification() -> TimeInterval? {
        guard let lastNotification = notificationHistory.last else { return nil }
        return Date().timeIntervalSince(lastNotification.timestamp)
    }
}
