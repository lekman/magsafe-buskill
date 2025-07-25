//
//  SystemActionsProtocol.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Protocol defining system actions for security service.
//  This allows for testability by separating business logic from system calls.
//

import Foundation

/// Protocol defining system-level security actions
public protocol SystemActionsProtocol {
    /// Lock the system screen
    func lockScreen() throws
    
    /// Play an alarm sound
    func playAlarm(volume: Float) throws
    
    /// Stop any ongoing alarm
    func stopAlarm()
    
    /// Force logout all users
    func forceLogout() throws
    
    /// Schedule system shutdown
    func scheduleShutdown(afterSeconds: TimeInterval) throws
    
    /// Execute a custom script
    func executeScript(at path: String) throws
}

/// Errors that can occur during system actions
public enum SystemActionError: LocalizedError {
    case screenLockFailed
    case alarmPlaybackFailed
    case logoutFailed
    case shutdownFailed
    case scriptNotFound
    case scriptExecutionFailed(exitCode: Int32)
    case permissionDenied
    
    public var errorDescription: String? {
        switch self {
        case .screenLockFailed:
            return "Failed to lock the screen"
        case .alarmPlaybackFailed:
            return "Failed to play alarm sound"
        case .logoutFailed:
            return "Failed to force logout"
        case .shutdownFailed:
            return "Failed to schedule shutdown"
        case .scriptNotFound:
            return "Custom script not found"
        case .scriptExecutionFailed(let exitCode):
            return "Script failed with exit code: \(exitCode)"
        case .permissionDenied:
            return "Permission denied for system action"
        }
    }
}