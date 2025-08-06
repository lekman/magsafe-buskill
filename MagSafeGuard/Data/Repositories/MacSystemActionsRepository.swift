//
//  MacSystemActionsRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation
import MagSafeGuardDomain
import os.log

/// macOS implementation of SecurityActionRepository with resource protection
public final class MacSystemActionsRepository: SecurityActionRepository, @unchecked Sendable {

    // MARK: - Properties

    private let systemActions: SystemActionsProtocol
    private let queue = DispatchQueue(label: "com.magsafeguard.systemactions.repository", qos: .userInitiated)
    private let resourceProtector: ResourceProtector
    private let logger = Logger(subsystem: "com.magsafeguard", category: "SystemActionsRepository")

    // MARK: - Initialization

    /// Initializes the macOS system actions repository with resource protection
    /// - Parameters:
    ///   - systemActions: The system actions implementation
    ///   - resourceProtectorConfig: Configuration for resource protection
    public init(
        systemActions: SystemActionsProtocol = MacSystemActions(),
        resourceProtectorConfig: ResourceProtectorConfig = .default
    ) {
        self.systemActions = systemActions
        self.resourceProtector = ResourceProtector(
            rateLimiterConfig: resourceProtectorConfig.rateLimiter,
            circuitBreakerConfig: resourceProtectorConfig.circuitBreaker
        )
    }

    // MARK: - SecurityActionRepository Implementation

    /// Locks the screen immediately with resource protection
    public func lockScreen() async throws {
        logger.debug("Attempting to lock screen")

        try await resourceProtector.executeProtected("lockScreen") {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                        return
                    }

                    do {
                        try self.systemActions.lockScreen()
                        self.logger.info("Screen locked successfully")
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to lock screen: \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapSystemError(error, for: .lockScreen))
                    }
                }
            }
        }
    }

    /// Plays an alarm sound at the specified volume with resource protection
    /// - Parameter volume: The volume level (0.0-1.0)
    public func playAlarm(volume: Float) async throws {
        logger.debug("Attempting to play alarm at volume: \(volume)")

        try await resourceProtector.executeProtected("playAlarm") {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                        return
                    }

                    do {
                        try self.systemActions.playAlarm(volume: volume)
                        self.logger.info("Alarm playing at volume: \(volume)")
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to play alarm: \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapSystemError(error, for: .soundAlarm))
                    }
                }
            }
        }
    }

    /// Stops any currently playing alarm
    public func stopAlarm() async {
        logger.debug("Stopping alarm")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                self?.systemActions.stopAlarm()
                self?.logger.info("Alarm stopped")
                continuation.resume()
            }
        }
    }

    /// Forces logout of all users with resource protection
    public func forceLogout() async throws {
        logger.warning("Attempting to force logout all users")

        try await resourceProtector.executeProtected("forceLogout") {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                        return
                    }

                    do {
                        try self.systemActions.forceLogout()
                        self.logger.warning("Force logout executed")
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to force logout: \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapSystemError(error, for: .forceLogout))
                    }
                }
            }
        }
    }

    /// Schedules a system shutdown after the specified delay with resource protection
    /// - Parameter afterSeconds: The delay before shutdown
    public func scheduleShutdown(afterSeconds: TimeInterval) async throws {
        logger.warning("Attempting to schedule shutdown in \(afterSeconds) seconds")

        try await resourceProtector.executeProtected("shutdown") {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                        return
                    }

                    do {
                        try self.systemActions.scheduleShutdown(afterSeconds: afterSeconds)
                        self.logger.warning("Shutdown scheduled for \(afterSeconds) seconds")
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to schedule shutdown: \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapSystemError(error, for: .shutdown))
                    }
                }
            }
        }
    }

    /// Executes a custom script at the specified path with enhanced security and resource protection
    /// - Parameter path: The path to the script file
    public func executeScript(at path: String) async throws {
        logger.warning("Attempting to execute script at path: \(path)")

        // Additional path validation
        guard validateScriptPath(path) else {
            logger.error("Invalid script path: \(path)")
            throw SecurityActionError.actionFailed(type: .customScript, reason: "Invalid script path")
        }

        try await resourceProtector.executeProtected("executeScript") {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                        return
                    }

                    do {
                        try self.systemActions.executeScript(at: path)
                        self.logger.warning("Script executed: \(path)")
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to execute script: \(error.localizedDescription)")
                        continuation.resume(throwing: self.mapSystemError(error, for: .customScript))
                    }
                }
            }
        }
    }

    // MARK: - Public Resource Protection Methods

    /// Get metrics for a specific action
    /// - Parameter action: The action type
    /// - Returns: Dictionary of metrics
    public func getMetrics(for action: SecurityActionType) async -> [String: Any] {
        let actionKey = mapActionTypeToKey(action)
        return await resourceProtector.getMetrics(for: actionKey)
    }

    /// Reset resource protection for a specific action
    /// - Parameter action: The action type
    public func resetProtection(for action: SecurityActionType) async {
        let actionKey = mapActionTypeToKey(action)
        await resourceProtector.reset(action: actionKey)
        logger.info("Reset protection for action: \(actionKey)")
    }

    /// Configure resource protection level
    /// - Parameter config: The resource protector configuration
    public func configureProtection(_ config: ResourceProtectorConfig) async {
        // This would require refactoring to support dynamic configuration
        // For now, configuration is set at initialization
        logger.info("Protection configuration request received")
    }

    // MARK: - Private Methods

    private func mapActionTypeToKey(_ action: SecurityActionType) -> String {
        switch action {
        case .lockScreen:
            return "lockScreen"
        case .soundAlarm:
            return "playAlarm"
        case .forceLogout:
            return "forceLogout"
        case .shutdown:
            return "shutdown"
        case .customScript:
            return "executeScript"
        @unknown default:
            return "unknown"
        }
    }

    private func validateScriptPath(_ path: String) -> Bool {
        // Security validation for script paths
        let url = URL(fileURLWithPath: path)

        // Check if path is absolute
        guard path.hasPrefix("/") else {
            logger.warning("Script path is not absolute: \(path)")
            return false
        }

        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            logger.warning("Script file does not exist: \(path)")
            return false
        }

        // Check file extension
        let allowedExtensions = ["sh", "bash", "zsh", "command"]
        guard allowedExtensions.contains(url.pathExtension) else {
            logger.warning("Script has invalid extension: \(url.pathExtension)")
            return false
        }

        // Check if path contains dangerous patterns
        let dangerousPatterns = ["../", "~", "${", "$(", "`"]
        for pattern in dangerousPatterns where path.contains(pattern) {
            logger.warning("Script path contains dangerous pattern: \(pattern)")
            return false
        }

        return true
    }

    private func mapSystemError(_ error: Error, for action: SecurityActionType) -> SecurityActionError {
        // Handle resource protection errors
        if let protectionError = error as? ResourceProtectionError {
            return mapResourceProtectionError(protectionError)
        }

        // Handle system action errors
        if let systemActionError = error as? SystemActionError {
            return mapSystemActionError(systemActionError, for: action)
        }

        return .systemError(description: error.localizedDescription)
    }

    private func mapResourceProtectionError(_ error: ResourceProtectionError) -> SecurityActionError {
        switch error {
        case .rateLimited(let action, let retryAfter):
            return .actionFailed(type: .customScript, reason: "Rate limited: \(action). Retry after \(Int(retryAfter))s")
        case .circuitOpen(let action, let state):
            return .actionFailed(type: .customScript, reason: "Circuit \(state) for \(action). Service temporarily unavailable")
        case .resourceExhausted(let action):
            return .actionFailed(type: .customScript, reason: "Resources exhausted for \(action)")
        case .protectionDisabled:
            return .systemError(description: "Resource protection is disabled")
        }
    }

    private func mapSystemActionError(_ error: SystemActionError, for action: SecurityActionType) -> SecurityActionError {
        switch error {
        case .screenLockFailed:
            return .actionFailed(type: .lockScreen, reason: "Failed to lock screen")
        case .alarmPlaybackFailed:
            return .actionFailed(type: .soundAlarm, reason: "Failed to play alarm")
        case .logoutFailed:
            return .actionFailed(type: .forceLogout, reason: "Failed to force logout")
        case .shutdownFailed:
            return .actionFailed(type: .shutdown, reason: "Failed to schedule shutdown")
        case .scriptNotFound:
            return .scriptNotFound(path: "Script file not found")
        case .scriptExecutionFailed(let exitCode):
            return .actionFailed(type: .customScript, reason: "Script failed with exit code: \(exitCode)")
        case .permissionDenied:
            return .permissionDenied(action: action)
        case .invalidScriptPath, .invalidScriptType, .insecureScriptPermissions,
             .dangerousScriptContent, .unauthorizedScriptHash, .scriptValidationFailed,
             .scriptNotExecutable:
            return mapScriptValidationError(error)
        case .scriptExecutionTimeout:
            return .actionFailed(type: .customScript, reason: "Script execution timed out")
        case .invalidShutdownDelay:
            return .actionFailed(type: .shutdown, reason: "Invalid shutdown delay value")
        }
    }

    private func mapScriptValidationError(_ error: SystemActionError) -> SecurityActionError {
        switch error {
        case .invalidScriptPath:
            return .actionFailed(type: .customScript, reason: "Invalid script path")
        case .invalidScriptType:
            return .actionFailed(type: .customScript, reason: "Invalid script file type")
        case .insecureScriptPermissions:
            return .actionFailed(type: .customScript, reason: "Script has insecure permissions")
        case .dangerousScriptContent:
            return .actionFailed(type: .customScript, reason: "Script contains dangerous commands")
        case .unauthorizedScriptHash:
            return .actionFailed(type: .customScript, reason: "Script is not authorized")
        case .scriptValidationFailed(let reason):
            return .actionFailed(type: .customScript, reason: "Script validation failed: \(reason)")
        case .scriptNotExecutable:
            return .actionFailed(type: .customScript, reason: "Script file is not executable")
        default:
            return .actionFailed(type: .customScript, reason: "Script error")
        }
    }
}
