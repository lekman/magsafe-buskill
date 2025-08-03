//
//  SecurityActionProtocols.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Domain layer protocols for security actions following Clean Architecture.
//  These protocols define the business rules for executing security measures
//  independent of any system implementation details.
//

import Foundation

// MARK: - Domain Models

/// Domain model representing a security action type.
/// All possible security responses to potential theft.
public enum SecurityActionType: String, CaseIterable, Equatable {
    case lockScreen = "lock_screen"
    case soundAlarm = "sound_alarm"
    case forceLogout = "force_logout"
    case shutdown = "shutdown"
    case customScript = "custom_script"

    /// User-friendly display name for the action.
    public var displayName: String {
        switch self {
        case .lockScreen: return "Lock Screen"
        case .soundAlarm: return "Sound Alarm"
        case .forceLogout: return "Force Logout"
        case .shutdown: return "System Shutdown"
        case .customScript: return "Custom Script"
        }
    }

    /// Detailed description of what the action does.
    public var description: String {
        switch self {
        case .lockScreen: return "Immediately lock the screen requiring authentication"
        case .soundAlarm: return "Play a loud alarm sound to deter theft"
        case .forceLogout: return "Force logout all users and lock screen"
        case .shutdown: return "Shutdown the system after a countdown"
        case .customScript: return "Execute a custom shell script"
        }
    }

    /// Whether this action is enabled by default.
    public var defaultEnabled: Bool {
        switch self {
        case .lockScreen: return true
        default: return false
        }
    }
}

/// Configuration for security actions.
/// Controls which actions execute and how.
public struct SecurityActionConfiguration: Equatable {
    /// Which security actions are enabled
    public let enabledActions: Set<SecurityActionType>
    /// Delay before executing actions (seconds)
    public let actionDelay: TimeInterval
    /// Volume for alarm action (0.0-1.0)
    public let alarmVolume: Float
    /// Delay before shutdown (seconds)
    public let shutdownDelay: TimeInterval
    /// Path to custom script if enabled
    public let customScriptPath: String?
    /// Whether to execute actions in parallel
    public let executeInParallel: Bool

    public init(
        enabledActions: Set<SecurityActionType> = [.lockScreen],
        actionDelay: TimeInterval = 0,
        alarmVolume: Float = 1.0,
        shutdownDelay: TimeInterval = 30,
        customScriptPath: String? = nil,
        executeInParallel: Bool = false
    ) {
        self.enabledActions = enabledActions
        self.actionDelay = actionDelay
        self.alarmVolume = min(max(alarmVolume, 0), 1) // Clamp to 0-1
        self.shutdownDelay = max(shutdownDelay, 0)
        self.customScriptPath = customScriptPath
        self.executeInParallel = executeInParallel
    }

    public static let `default` = SecurityActionConfiguration()
}

/// Security action execution request
public struct SecurityActionRequest: Equatable {
    public let configuration: SecurityActionConfiguration
    public let trigger: SecurityTrigger
    public let timestamp: Date

    public init(
        configuration: SecurityActionConfiguration,
        trigger: SecurityTrigger,
        timestamp: Date = Date()
    ) {
        self.configuration = configuration
        self.trigger = trigger
        self.timestamp = timestamp
    }
}

/// What triggered the security action
public enum SecurityTrigger: Equatable {
    case powerDisconnected
    case manualTrigger
    case testTrigger
    case customTrigger(String)

    /// Human-readable description of the trigger.
    public var description: String {
        switch self {
        case .powerDisconnected:
            return "Power adapter disconnected"
        case .manualTrigger:
            return "Manually triggered by user"
        case .testTrigger:
            return "Test trigger"
        case .customTrigger(let reason):
            return reason
        }
    }
}

/// Result of executing security actions
public struct SecurityActionExecutionResult: Equatable {
    public let request: SecurityActionRequest
    public let executedActions: [SecurityActionResult]
    public let startTime: Date
    public let endTime: Date

    public init(
        request: SecurityActionRequest,
        executedActions: [SecurityActionResult],
        startTime: Date,
        endTime: Date
    ) {
        self.request = request
        self.executedActions = executedActions
        self.startTime = startTime
        self.endTime = endTime
    }

    public var allSucceeded: Bool {
        executedActions.allSatisfy { $0.success }
    }

    public var failedActions: [SecurityActionResult] {
        executedActions.filter { !$0.success }
    }

    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

/// Result of a single action execution
public struct SecurityActionResult: Equatable {
    public let actionType: SecurityActionType
    public let success: Bool
    public let error: SecurityActionError?
    public let executedAt: Date

    public init(
        actionType: SecurityActionType,
        success: Bool,
        error: SecurityActionError? = nil,
        executedAt: Date = Date()
    ) {
        self.actionType = actionType
        self.success = success
        self.error = error
        self.executedAt = executedAt
    }
}

/// Security action execution errors
public enum SecurityActionError: LocalizedError, Equatable {
    case actionFailed(type: SecurityActionType, reason: String)
    case alreadyExecuting
    case scriptNotFound(path: String)
    case permissionDenied(action: SecurityActionType)
    case systemError(description: String)
    case invalidConfiguration(reason: String)

    public var errorDescription: String? {
        switch self {
        case .actionFailed(let type, let reason):
            return "\(type.displayName) failed: \(reason)"
        case .alreadyExecuting:
            return "Security actions are already being executed"
        case .scriptNotFound(let path):
            return "Script not found at path: \(path)"
        case .permissionDenied(let action):
            return "Permission denied for action: \(action.displayName)"
        case .systemError(let description):
            return "System error: \(description)"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
}

// MARK: - Repository Protocol

/// Repository for executing system-level security actions
public protocol SecurityActionRepository {
    /// Lock the screen
    func lockScreen() async throws

    /// Play alarm sound
    func playAlarm(volume: Float) async throws

    /// Stop alarm sound
    func stopAlarm() async

    /// Force logout all users
    func forceLogout() async throws

    /// Schedule system shutdown
    func scheduleShutdown(afterSeconds: TimeInterval) async throws

    /// Execute custom script
    func executeScript(at path: String) async throws
}

// MARK: - Use Case Protocols

/// Use case for executing security actions
public protocol SecurityActionExecutionUseCase {
    /// Execute security actions based on configuration
    func executeActions(request: SecurityActionRequest) async -> SecurityActionExecutionResult

    /// Check if actions are currently executing
    func isExecuting() async -> Bool

    /// Stop any ongoing actions (like alarms)
    func stopOngoingActions() async
}

/// Use case for managing security action configuration
public protocol SecurityActionConfigurationUseCase {
    /// Get current configuration
    func getCurrentConfiguration() async -> SecurityActionConfiguration

    /// Update configuration
    func updateConfiguration(_ configuration: SecurityActionConfiguration) async throws

    /// Validate configuration
    func validateConfiguration(_ configuration: SecurityActionConfiguration) -> Result<Void, SecurityActionError>

    /// Reset to default configuration
    func resetToDefault() async
}

// MARK: - Execution Strategy

/// Strategy for executing multiple actions
public protocol SecurityActionExecutionStrategy {
    /// Execute actions and return results
    func executeActions(
        _ actions: [SecurityActionType],
        configuration: SecurityActionConfiguration,
        repository: SecurityActionRepository
    ) async -> [SecurityActionResult]
}

/// Sequential execution strategy
public struct SequentialExecutionStrategy: SecurityActionExecutionStrategy {
    public init() {}

    public func executeActions(
        _ actions: [SecurityActionType],
        configuration: SecurityActionConfiguration,
        repository: SecurityActionRepository
    ) async -> [SecurityActionResult] {
        var results: [SecurityActionResult] = []

        for action in actions {
            let result = await executeAction(
                action,
                configuration: configuration,
                repository: repository
            )
            results.append(result)
        }

        return results
    }

    private func executeAction(
        _ action: SecurityActionType,
        configuration: SecurityActionConfiguration,
        repository: SecurityActionRepository
    ) async -> SecurityActionResult {
        do {
            switch action {
            case .lockScreen:
                try await repository.lockScreen()
            case .soundAlarm:
                try await repository.playAlarm(volume: configuration.alarmVolume)
            case .forceLogout:
                try await repository.forceLogout()
            case .shutdown:
                try await repository.scheduleShutdown(afterSeconds: configuration.shutdownDelay)
            case .customScript:
                guard let path = configuration.customScriptPath else {
                    throw SecurityActionError.scriptNotFound(path: "No path configured")
                }
                try await repository.executeScript(at: path)
            }

            return SecurityActionResult(
                actionType: action,
                success: true,
                error: nil
            )
        } catch {
            return SecurityActionResult(
                actionType: action,
                success: false,
                error: mapError(error, for: action)
            )
        }
    }

    private func mapError(_ error: Error, for action: SecurityActionType) -> SecurityActionError {
        if let securityError = error as? SecurityActionError {
            return securityError
        }
        return .actionFailed(type: action, reason: error.localizedDescription)
    }
}

/// Parallel execution strategy
public struct ParallelExecutionStrategy: SecurityActionExecutionStrategy {
    public init() {}

    public func executeActions(
        _ actions: [SecurityActionType],
        configuration: SecurityActionConfiguration,
        repository: SecurityActionRepository
    ) async -> [SecurityActionResult] {
        await withTaskGroup(of: SecurityActionResult.self) { group in
            for action in actions {
                group.addTask {
                    await executeAction(
                        action,
                        configuration: configuration,
                        repository: repository
                    )
                }
            }

            var results: [SecurityActionResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    private func executeAction(
        _ action: SecurityActionType,
        configuration: SecurityActionConfiguration,
        repository: SecurityActionRepository
    ) async -> SecurityActionResult {
        // Implementation identical to SequentialExecutionStrategy
        do {
            switch action {
            case .lockScreen:
                try await repository.lockScreen()
            case .soundAlarm:
                try await repository.playAlarm(volume: configuration.alarmVolume)
            case .forceLogout:
                try await repository.forceLogout()
            case .shutdown:
                try await repository.scheduleShutdown(afterSeconds: configuration.shutdownDelay)
            case .customScript:
                guard let path = configuration.customScriptPath else {
                    throw SecurityActionError.scriptNotFound(path: "No path configured")
                }
                try await repository.executeScript(at: path)
            }

            return SecurityActionResult(
                actionType: action,
                success: true,
                error: nil
            )
        } catch {
            return SecurityActionResult(
                actionType: action,
                success: false,
                error: mapError(error, for: action)
            )
        }
    }

    private func mapError(_ error: Error, for action: SecurityActionType) -> SecurityActionError {
        if let securityError = error as? SecurityActionError {
            return securityError
        }
        return .actionFailed(type: action, reason: error.localizedDescription)
    }
}
