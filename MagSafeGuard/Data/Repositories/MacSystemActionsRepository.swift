//
//  MacSystemActionsRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation

/// macOS implementation of SecurityActionRepository
public final class MacSystemActionsRepository: SecurityActionRepository {

    // MARK: - Properties

    private let systemActions: SystemActionsProtocol
    private let queue = DispatchQueue(label: "com.magsafeguard.systemactions.repository", qos: .userInitiated)

    // MARK: - Initialization

    public init(systemActions: SystemActionsProtocol = MacSystemActions()) {
        self.systemActions = systemActions
    }

    // MARK: - SecurityActionRepository Implementation

    public func lockScreen() async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                    return
                }

                do {
                    try self.systemActions.lockScreen()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: self.mapSystemError(error, for: .lockScreen))
                }
            }
        }
    }

    public func playAlarm(volume: Float) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                    return
                }

                do {
                    try self.systemActions.playAlarm(volume: volume)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: self.mapSystemError(error, for: .soundAlarm))
                }
            }
        }
    }

    public func stopAlarm() async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                self?.systemActions.stopAlarm()
                continuation.resume()
            }
        }
    }

    public func forceLogout() async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                    return
                }

                do {
                    try self.systemActions.forceLogout()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: self.mapSystemError(error, for: .forceLogout))
                }
            }
        }
    }

    public func scheduleShutdown(afterSeconds: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                    return
                }

                do {
                    try self.systemActions.scheduleShutdown(afterSeconds: afterSeconds)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: self.mapSystemError(error, for: .shutdown))
                }
            }
        }
    }

    public func executeScript(at path: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: SecurityActionError.systemError(description: "Service unavailable"))
                    return
                }

                do {
                    try self.systemActions.executeScript(at: path)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: self.mapSystemError(error, for: .customScript))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func mapSystemError(_ error: Error, for action: SecurityActionType) -> SecurityActionError {
        if let systemActionError = error as? SystemActionError {
            switch systemActionError {
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
            }
        }

        return .systemError(description: error.localizedDescription)
    }
}
