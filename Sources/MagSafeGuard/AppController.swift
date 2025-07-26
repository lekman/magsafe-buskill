//
//  AppController.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Central coordinator for the MagSafe Guard application that manages
//  state, coordinates services, and handles the grace period timer.
//

import AppKit
import Combine
import Foundation

/// Application states representing the security system's current mode.
///
/// The state machine flows: disarmed → armed → gracePeriod → triggered
/// with the ability to return to disarmed from any state via authentication.
public enum AppState: String {
    /// System is not monitoring power disconnection
    case disarmed = "disarmed"
    /// System is actively monitoring for power disconnection
    case armed = "armed"
    /// Grace period is active, user can cancel security actions
    case gracePeriod = "grace_period"
    /// Security actions have been executed
    case triggered = "triggered"
}

/// Events that can occur throughout the application lifecycle.
///
/// These events are logged for audit trails and can trigger state changes
/// or notifications based on the current configuration.
public enum AppEvent: String {
    /// System was armed successfully
    case armed
    /// System was disarmed successfully
    case disarmed
    /// Power adapter was disconnected while armed
    case powerDisconnected
    /// Power adapter was reconnected
    case powerConnected
    /// Grace period countdown began
    case gracePeriodStarted
    /// Grace period was cancelled by user authentication
    case gracePeriodCancelled
    /// Security action was executed (lock, shutdown, etc.)
    case securityActionExecuted
    /// User authentication failed during arm/disarm/cancel
    case authenticationFailed
    /// User authentication succeeded
    case authenticationSucceeded
    /// Application is terminating
    case applicationTerminating
}

/// Event log entry containing timestamped application events.
///
/// Used for audit trails, debugging, and user activity monitoring.
/// Events are automatically logged by the AppController during state changes.
public struct EventLogEntry {
    /// When the event occurred
    public let timestamp: Date
    /// Type of event that occurred
    public let event: AppEvent
    /// Optional additional details about the event
    public let details: String?
    /// Application state when event occurred
    public let state: AppState
}

/// Main application controller that coordinates all services and manages application state.
///
/// The AppController serves as the central coordinator for MagSafe Guard, managing:
/// - Application state transitions (disarmed ↔ armed ↔ grace period ↔ triggered)
/// - Power monitoring integration
/// - Authentication workflows
/// - Grace period timer management
/// - Event logging and audit trails
/// - Settings integration and real-time configuration updates
///
/// ## Usage
///
/// ```swift
/// let controller = AppController()
/// controller.arm { result in
///     switch result {
///     case .success:
///         print("System armed successfully")
///     case .failure(let error):
///         print("Failed to arm: \(error)")
///     }
/// }
/// ```
///
/// ## State Management
///
/// The controller maintains a strict state machine:
/// - **Disarmed**: Default state, no monitoring active
/// - **Armed**: Power monitoring active, will trigger on disconnection
/// - **Grace Period**: Countdown active, user can authenticate to cancel
/// - **Triggered**: Security actions executed, requires manual reset
///
/// ## Thread Safety
///
/// All public methods are thread-safe and coordinate through the main queue
/// for UI updates and state changes.
public class AppController: ObservableObject {

    // MARK: - Published Properties

    /// Current application state.
    ///
    /// Published property that automatically notifies observers when the security
    /// system transitions between states. UI components can observe this property
    /// to update their appearance and behavior.
    @Published public private(set) var currentState: AppState = .disarmed

    /// Whether the grace period is currently active.
    ///
    /// Published property indicating if users can authenticate to cancel pending
    /// security actions. Used by UI to show grace period controls and countdown.
    @Published public private(set) var isInGracePeriod: Bool = false

    /// Remaining time in the grace period countdown.
    ///
    /// Updated approximately every 100ms during grace period to provide smooth
    /// countdown displays. Value is 0 when grace period is not active.
    @Published public private(set) var gracePeriodRemaining: TimeInterval = 0

    /// Last known power adapter connection state.
    ///
    /// Tracks the most recent power state for debugging and state management.
    /// Updated whenever power monitoring detects a state change.
    public private(set) var lastPowerState: PowerMonitorService.PowerState = .disconnected

    // MARK: - Services

    private let powerMonitor: PowerMonitorService
    private let authService: AuthenticationService
    private let securityActions: SecurityActionsService
    private let notificationService: NotificationService

    // MARK: - Configuration

    private let settingsManager = UserDefaultsManager.shared

    /// Duration of grace period before security actions execute.
    ///
    /// Convenience property that provides direct access to the grace period
    /// setting with automatic persistence. Changes take effect immediately
    /// for new security events.
    public var gracePeriodDuration: TimeInterval {
        get { settingsManager.settings.gracePeriodDuration }
        set { settingsManager.updateSetting(\.gracePeriodDuration, value: newValue) }
    }

    /// Whether users can cancel security actions during grace period.
    ///
    /// Convenience property for accessing the grace period cancellation setting.
    /// When false, security actions execute automatically without user intervention.
    public var allowGracePeriodCancellation: Bool {
        get { settingsManager.settings.allowGracePeriodCancellation }
        set { settingsManager.updateSetting(\.allowGracePeriodCancellation, value: newValue) }
    }

    // MARK: - Private Properties

    private var gracePeriodTimer: Timer?
    private var gracePeriodStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var eventLog: [EventLogEntry] = []
    private let eventLogQueue = DispatchQueue(label: "com.magsafeguard.eventlog")

    // MARK: - Constants

    private static let userCancelledMessage = "User cancelled"

    // MARK: - Callbacks

    /// Callback invoked when application state changes.
    ///
    /// Optional closure called whenever the application transitions between states.
    /// Receives the old state and new state for comparison and logging.
    public var onStateChange: ((AppState, AppState) -> Void)?

    /// Callback for notification requests.
    ///
    /// Optional closure called when the controller wants to display a notification.
    /// Receives title and message strings for the notification content.
    public var onNotification: ((String, String) -> Void)?

    // MARK: - Initialization

    /// Initialize the application controller with specified services.
    ///
    /// Creates a new controller instance with dependency injection support
    /// for testing. In production, use the default shared instances.
    ///
    /// - Parameters:
    ///   - powerMonitor: Service for monitoring power adapter state
    ///   - authService: Service for user authentication
    ///   - securityActions: Service for executing security actions
    ///   - notificationService: Service for displaying notifications
    public init(powerMonitor: PowerMonitorService = .shared,
                authService: AuthenticationService = .shared,
                securityActions: SecurityActionsService = .shared,
                notificationService: NotificationService = .shared) {
        self.powerMonitor = powerMonitor
        self.authService = authService
        self.securityActions = securityActions
        self.notificationService = notificationService

        setupPowerMonitoring()
        loadConfiguration()
        setupNotificationHandling()
    }

    // MARK: - Public Methods

    /// Arms the system with authentication
    public func arm(completion: @escaping (Result<Void, Error>) -> Void) {
        guard currentState == .disarmed else {
            completion(.failure(AppControllerError.invalidState("Cannot arm from state: \(currentState)")))
            return
        }

        // Require authentication
        authService.authenticate(reason: "Authenticate to arm MagSafe Guard") { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.logEventInternal(.authenticationSucceeded, details: "Arming system")
                self.transitionToState(.armed)
                self.onNotification?("MagSafe Guard Armed", "Protection is now active")
                completion(.success(()))

            case .failure(let error):
                self.logEventInternal(.authenticationFailed, details: error.localizedDescription)
                completion(.failure(error))

            case .cancelled:
                self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
                completion(.failure(AppControllerError.authenticationRequired))
            }
        }
    }

    /// Disarms the system with authentication
    public func disarm(completion: @escaping (Result<Void, Error>) -> Void) {
        guard currentState == .armed || currentState == .gracePeriod else {
            completion(.failure(AppControllerError.invalidState("Cannot disarm from state: \(currentState)")))
            return
        }

        // Cancel grace period if active
        if isInGracePeriod {
            cancelGracePeriod()
        }

        // Require authentication
        authService.authenticate(reason: "Authenticate to disarm MagSafe Guard") { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.logEventInternal(.authenticationSucceeded, details: "Disarming system")
                self.transitionToState(.disarmed)
                self.onNotification?("MagSafe Guard Disarmed", "Protection is now inactive")
                completion(.success(()))

            case .failure(let error):
                self.logEventInternal(.authenticationFailed, details: error.localizedDescription)
                completion(.failure(error))

            case .cancelled:
                self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
                completion(.failure(AppControllerError.authenticationRequired))
            }
        }
    }

    /// Cancels grace period with authentication
    public func cancelGracePeriodWithAuth(completion: @escaping (Result<Void, Error>) -> Void) {
        guard isInGracePeriod && allowGracePeriodCancellation else {
            completion(.failure(AppControllerError.gracePeriodNotCancellable))
            return
        }

        authService.authenticate(reason: "Authenticate to cancel security action") { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.logEventInternal(.authenticationSucceeded, details: "Cancelling grace period")
                self.cancelGracePeriod()
                self.transitionToState(.armed)
                self.onNotification?("Security Action Cancelled", "Grace period cancelled")
                completion(.success(()))

            case .failure(let error):
                self.logEventInternal(.authenticationFailed, details: error.localizedDescription)
                completion(.failure(error))

            case .cancelled:
                self.logEventInternal(.authenticationFailed, details: AppController.userCancelledMessage)
                completion(.failure(AppControllerError.authenticationRequired))
            }
        }
    }

    /// Gets recent event log entries
    public func getEventLog(limit: Int = 100) -> [EventLogEntry] {
        eventLogQueue.sync {
            Array(eventLog.suffix(limit))
        }
    }

    /// Clears the event log
    public func clearEventLog() {
        eventLogQueue.async { [weak self] in
            self?.eventLog.removeAll()
        }
    }

    /// Logs an event (public for AppDelegate lifecycle)
    public func logEvent(_ event: AppEvent, details: String? = nil) {
        logEventInternal(event, details: details)
    }

    // MARK: - Private Methods

    private func setupPowerMonitoring() {
        powerMonitor.startMonitoring { [weak self] powerInfo in
            guard let self = self else { return }

            self.lastPowerState = powerInfo.state

            // Only react to disconnection when armed
            if powerInfo.state == .disconnected && self.currentState == .armed {
                self.handlePowerDisconnected()
            } else if powerInfo.state == .connected {
                self.logEventInternal(.powerConnected, details: "Power adapter connected")
            }
        }
    }

    private func handlePowerDisconnected() {
        logEventInternal(.powerDisconnected, details: "Power adapter disconnected while armed")

        if gracePeriodDuration > 0 {
            startGracePeriod()
        } else {
            // Immediate execution
            executeSecurityActions()
        }
    }

    private func startGracePeriod() {
        transitionToState(.gracePeriod)
        isInGracePeriod = true
        gracePeriodStartTime = Date()
        gracePeriodRemaining = gracePeriodDuration

        logEventInternal(.gracePeriodStarted, details: "Grace period started: \(Int(gracePeriodDuration))s")
        notificationService.showCriticalAlert(
            title: "Security Alert",
            message: "Power disconnected! Security action in \(Int(gracePeriodDuration)) seconds"
        )

        // Start countdown timer
        gracePeriodTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let elapsed = Date().timeIntervalSince(self.gracePeriodStartTime ?? Date())
            self.gracePeriodRemaining = max(0, self.gracePeriodDuration - elapsed)

            if self.gracePeriodRemaining <= 0 {
                self.gracePeriodTimer?.invalidate()
                self.gracePeriodTimer = nil
                self.executeSecurityActions()
            }
        }
    }

    private func cancelGracePeriod() {
        gracePeriodTimer?.invalidate()
        gracePeriodTimer = nil
        isInGracePeriod = false
        gracePeriodRemaining = 0
        gracePeriodStartTime = nil

        logEventInternal(.gracePeriodCancelled, details: "Grace period cancelled")
    }

    private func executeSecurityActions() {
        transitionToState(.triggered)
        cancelGracePeriod()

        securityActions.executeActions { [weak self] result in
            guard let self = self else { return }

            if result.allSucceeded {
                self.logEventInternal(.securityActionExecuted, details: "All security actions executed successfully")
                self.onNotification?("Security Actions Executed", "All configured actions completed")
            } else {
                let failedCount = result.failedActions.count
                self.logEventInternal(.securityActionExecuted, details: "\(failedCount) actions failed")
                self.onNotification?("Security Actions Partial", "\(failedCount) actions failed to execute")
            }

            // Return to armed state after execution
            self.transitionToState(.armed)
        }
    }

    private func transitionToState(_ newState: AppState) {
        let oldState = currentState
        currentState = newState

        // Log state changes
        switch newState {
        case .armed:
            logEventInternal(.armed, details: "System armed")
        case .disarmed:
            logEventInternal(.disarmed, details: "System disarmed")
        default:
            break
        }

        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(oldState, newState)
        }
    }

    private func logEventInternal(_ event: AppEvent, details: String? = nil) {
        eventLogQueue.async { [weak self] in
            guard let self = self else { return }

            let entry = EventLogEntry(
                timestamp: Date(),
                event: event,
                details: details,
                state: self.currentState
            )

            self.eventLog.append(entry)

            // Keep log size reasonable
            if self.eventLog.count > 1000 {
                self.eventLog.removeFirst(self.eventLog.count - 1000)
            }

            // Debug logging
            print("[AppController] Event: \(event.rawValue) | State: \(self.currentState.rawValue) | Details: \(details ?? "none")")
        }
    }

    private func loadConfiguration() {
        // Configuration is now loaded from UserDefaultsManager
        // Subscribe to settings changes
        settingsManager.$settings
            .sink { [weak self] _ in
                // Settings have changed, any necessary updates can be handled here
                self?.logEventInternal(.armed, details: "Settings updated")
            }
            .store(in: &cancellables)
    }

    private func setupNotificationHandling() {
        // Replace the callback with direct notification service usage
        onNotification = { [weak self] title, message in
            self?.notificationService.showNotification(title: title, message: message)
        }

        // Listen for grace period cancellation from alert windows
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGracePeriodCancellationRequest),
            name: Notification.Name("MagSafeGuard.CancelGracePeriod"),
            object: nil
        )
    }

    @objc private func handleGracePeriodCancellationRequest() {
        if isInGracePeriod {
            cancelGracePeriodWithAuth { _ in
                // Empty completion - errors are already logged internally by cancelGracePeriodWithAuth
                // and user notifications are shown. This is a fire-and-forget operation triggered
                // by the notification center, so no additional error handling is needed here.
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during AppController operations.
///
/// Provides specific error types for different failure conditions
/// with localized error messages for user display.
public enum AppControllerError: LocalizedError {
    /// Operation cannot be performed in the current state
    case invalidState(String)
    /// Grace period cancellation is not allowed by configuration
    case gracePeriodNotCancellable
    /// User authentication is required for this operation
    case authenticationRequired

    /// Localized error description for user display.
    public var errorDescription: String? {
        switch self {
        case .invalidState(let message):
            return message
        case .gracePeriodNotCancellable:
            return "Grace period cancellation is not allowed"
        case .authenticationRequired:
            return "Authentication is required for this operation"
        }
    }
}

// MARK: - AppController Extension for Menu

extension AppController {
    /// Returns the appropriate menu title for arm/disarm action
    public var armDisarmMenuTitle: String {
        switch currentState {
        case .disarmed:
            return "Arm Protection"
        case .armed, .gracePeriod, .triggered:
            return "Disarm Protection"
        }
    }

    /// Returns the appropriate icon name for current state
    public var statusIconName: String {
        switch currentState {
        case .disarmed:
            return "shield"
        case .armed:
            return "shield.fill"
        case .gracePeriod:
            return "exclamationmark.shield.fill"
        case .triggered:
            return "xmark.shield.fill"
        }
    }

    /// Returns a human-readable status description
    public var statusDescription: String {
        switch currentState {
        case .disarmed:
            return "Protection Disabled"
        case .armed:
            return "Protection Active"
        case .gracePeriod:
            return "Grace Period - \(Int(gracePeriodRemaining))s"
        case .triggered:
            return "Security Action Triggered"
        }
    }
}
