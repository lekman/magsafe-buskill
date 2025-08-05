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

/// Protocol defining system-level security actions.
///
/// SystemActionsProtocol abstracts platform-specific system operations to enable
/// testing and provide a clean separation between business logic and system calls.
/// Implementations handle the actual system integration while maintaining a
/// consistent interface for the security service.
///
/// ## Implementation Notes
///
/// - All methods may require elevated privileges on some systems
/// - Error handling should be comprehensive with specific error types
/// - Operations should be atomic where possible
/// - Some actions (like shutdown) may not complete immediately
///
/// ## Testing
///
/// This protocol enables dependency injection of mock implementations for
/// comprehensive testing without actually performing system actions.
public protocol SystemActionsProtocol {
  /// Lock the system screen immediately.
  ///
  /// Triggers the system screen lock, requiring user authentication to unlock.
  /// This is typically the fastest and most reliable security action.
  ///
  /// - Throws: `SystemActionError.screenLockFailed` if the lock operation fails
  func lockScreen() throws

  /// Play an alarm sound at the specified volume.
  ///
  /// Initiates audio alarm playback to deter theft and alert nearby people.
  /// The alarm continues until stopped manually or the system is powered off.
  ///
  /// - Parameter volume: Audio volume level (0.0 to 1.0)
  /// - Throws: `SystemActionError.alarmPlaybackFailed` if audio cannot be played
  func playAlarm(volume: Float) throws

  /// Stop any ongoing alarm sound playback.
  ///
  /// Terminates active alarm audio without affecting other security actions.
  /// Safe to call even if no alarm is currently playing.
  func stopAlarm()

  /// Force logout all current user sessions.
  ///
  /// Immediately terminates all user sessions and returns to the login screen.
  /// More comprehensive than screen lock as it also closes all applications.
  ///
  /// - Throws: `SystemActionError.logoutFailed` if logout cannot be performed
  func forceLogout() throws

  /// Schedule system shutdown after a delay.
  ///
  /// Initiates a delayed system shutdown, giving users time to save work.
  /// The shutdown can often be cancelled through normal system interfaces
  /// if the user regains access.
  ///
  /// - Parameter afterSeconds: Delay before shutdown begins
  /// - Throws: `SystemActionError.shutdownFailed` if shutdown cannot be scheduled
  func scheduleShutdown(afterSeconds: TimeInterval) throws

  /// Execute a custom script at the specified path.
  ///
  /// Runs a user-defined script to perform custom security actions.
  /// Scripts should be validated and trusted as they run with user privileges.
  ///
  /// - Parameter path: Absolute path to the script file
  /// - Throws: `SystemActionError.scriptNotFound` if script doesn't exist,
  ///   `SystemActionError.scriptExecutionFailed` if execution fails,
  ///   `SystemActionError.permissionDenied` if insufficient permissions
  func executeScript(at path: String) throws
}

/// Errors that can occur during system action execution.
///
/// Provides specific error types for different system action failures,
/// enabling appropriate error handling and user feedback.
public enum SystemActionError: LocalizedError {
  /// Screen lock operation failed
  case screenLockFailed
  /// Alarm sound playback failed
  case alarmPlaybackFailed
  /// User logout operation failed
  case logoutFailed
  /// System shutdown scheduling failed
  case shutdownFailed
  /// Custom script file not found
  case scriptNotFound
  /// Script execution failed with specific exit code
  case scriptExecutionFailed(exitCode: Int32)
  /// Insufficient permissions for system action
  case permissionDenied
  /// Invalid script path (security violation)
  case invalidScriptPath
  /// Invalid script file type
  case invalidScriptType
  /// Script has insecure permissions
  case insecureScriptPermissions
  /// Invalid shutdown delay value
  case invalidShutdownDelay

  /// Localized error description for user display.
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
    case .invalidScriptPath:
      return "Script path is not allowed for security reasons"
    case .invalidScriptType:
      return "Script file type is not supported"
    case .insecureScriptPermissions:
      return "Script has insecure file permissions"
    case .invalidShutdownDelay:
      return "Invalid shutdown delay value"
    }
  }
}
