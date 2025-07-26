//
//  AppController.swift
//  MagSafe Guard
//
//  Created on 2025-07-26.
//
//  Central coordinator for the MagSafe Guard application that manages
//  state, coordinates services, and handles the grace period timer.
//

import Foundation
import Combine
import AppKit

/// Application states
public enum AppState: String {
    case disarmed = "disarmed"
    case armed = "armed"
    case gracePeriod = "grace_period"
    case triggered = "triggered"
}

/// Events that can occur in the application
public enum AppEvent: String {
    case armed
    case disarmed
    case powerDisconnected
    case powerConnected
    case gracePeriodStarted
    case gracePeriodCancelled
    case securityActionExecuted
    case authenticationFailed
    case authenticationSucceeded
    case applicationTerminating
}

/// Event log entry
public struct EventLogEntry {
    let timestamp: Date
    let event: AppEvent
    let details: String?
    let state: AppState
}

/// Main application controller that coordinates all services
public class AppController: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var currentState: AppState = .disarmed
    @Published public private(set) var isInGracePeriod: Bool = false
    @Published public private(set) var gracePeriodRemaining: TimeInterval = 0
    public private(set) var lastPowerState: PowerMonitorService.PowerState = .disconnected
    
    // MARK: - Services
    
    private let powerMonitor: PowerMonitorService
    private let authService: AuthenticationService
    private let securityActions: SecurityActionsService
    private let notificationService: NotificationService
    
    // MARK: - Configuration
    
    public var gracePeriodDuration: TimeInterval = 10.0 // Default 10 seconds
    public var allowGracePeriodCancellation: Bool = true
    
    // MARK: - Private Properties
    
    private var gracePeriodTimer: Timer?
    private var gracePeriodStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var eventLog: [EventLogEntry] = []
    private let eventLogQueue = DispatchQueue(label: "com.magsafeguard.eventlog")
    
    // MARK: - Constants
    
    private static let userCancelledMessage = "User cancelled"
    
    // MARK: - Callbacks
    
    public var onStateChange: ((AppState, AppState) -> Void)?
    public var onNotification: ((String, String) -> Void)?
    
    // MARK: - Initialization
    
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
        // TODO: Load from configuration file
        // For now, use defaults
        gracePeriodDuration = 10.0
        allowGracePeriodCancellation = true
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

public enum AppControllerError: LocalizedError {
    case invalidState(String)
    case gracePeriodNotCancellable
    case authenticationRequired
    
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