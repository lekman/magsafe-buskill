//
//  MacSystemActions.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Real implementation of system actions for macOS.
//

import AppKit
import AVFoundation
import Foundation

/// Real implementation of system actions for macOS
public class MacSystemActions: SystemActionsProtocol {

    private var alarmPlayer: AVAudioPlayer?

    /// Configuration for system command paths
    public struct SystemPaths {
        let pmsetPath: String
        let osascriptPath: String
        let killallPath: String
        let sudoPath: String
        let bashPath: String

        /// Default system paths for macOS standard locations
        public static let `default` = SystemPaths(
            pmsetPath: "/usr/bin/pmset",
            osascriptPath: "/usr/bin/osascript",
            killallPath: "/usr/bin/killall",
            sudoPath: "/usr/bin/sudo",
            bashPath: "/bin/bash"
        )
    }

    private let systemPaths: SystemPaths

    /// Initialize with custom system paths for testing
    /// - Parameter systemPaths: Custom paths to system utilities
    public init(systemPaths: SystemPaths = .default) {
        self.systemPaths = systemPaths
    }

    /// Locks the screen using distributed notification center
    /// - Throws: SystemActionError if the operation fails
    public func lockScreen() throws {
        // Use distributed notification center to lock screen
        let notificationName = "com.apple.screenIsLocked" as CFString
        let notificationCenter = CFNotificationCenterGetDistributedCenter()

        // Post notification to lock screen
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName(notificationName),
            nil,
            nil,
            true
        )

        // Alternative method using system command
        let task = Process()
        task.launchPath = systemPaths.pmsetPath
        task.arguments = ["displaysleepnow"]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                throw SystemActionError.screenLockFailed
            }
        } catch {
            Log.error("Screen lock failed", error: error, category: .security)
            throw SystemActionError.screenLockFailed
        }
    }

    /// Plays an alarm sound at the specified volume
    /// - Parameter volume: Volume level from 0.0 to 1.0
    /// - Throws: SystemActionError if playback fails
    public func playAlarm(volume: Float) throws {
        // Play alarm sound
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            // Use system sound as fallback
            NSSound.beep()

            // Play multiple beeps
            for _ in 0..<5 {
                NSSound.beep()
                Thread.sleep(forTimeInterval: 0.5)
            }
            return
        }

        do {
            alarmPlayer = try AVAudioPlayer(contentsOf: soundURL)
            alarmPlayer?.volume = volume
            alarmPlayer?.numberOfLoops = -1 // Loop indefinitely
            alarmPlayer?.play()
        } catch {
            Log.error("Failed to play alarm sound", error: error, category: .security)
            // Fallback to system beep
            NSSound.beep()
            throw SystemActionError.alarmPlaybackFailed
        }
    }

    /// Stops the currently playing alarm sound
    public func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
    }

    /// Forces logout of all users using AppleScript
    /// - Throws: SystemActionError if the operation fails
    public func forceLogout() throws {
        // Force logout all users
        let task = Process()
        task.launchPath = systemPaths.osascriptPath
        task.arguments = ["-e", "tell application \"System Events\" to log out"]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                throw SystemActionError.logoutFailed
            }
        } catch {
            Log.error("Force logout failed", error: error, category: .security)
            throw SystemActionError.logoutFailed
        }
    }

    /// Schedules system shutdown after specified delay
    /// - Parameter afterSeconds: Delay before shutdown in seconds
    /// - Throws: SystemActionError if scheduling fails
    public func scheduleShutdown(afterSeconds: TimeInterval) throws {
        // Schedule system shutdown
        let task = Process()
        task.launchPath = systemPaths.sudoPath
        task.arguments = ["-n", "shutdown", "-h", "+\(Int(afterSeconds / 60))"]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                // Try alternative method without sudo
                let alternativeTask = Process()
                alternativeTask.launchPath = systemPaths.osascriptPath
                alternativeTask.arguments = ["-e", "tell application \"System Events\" to shut down"]
                try alternativeTask.run()
                alternativeTask.waitUntilExit()

                if alternativeTask.terminationStatus != 0 {
                    throw SystemActionError.shutdownFailed
                }
            }
        } catch {
            Log.error("Shutdown failed", error: error, category: .security)
            throw SystemActionError.shutdownFailed
        }
    }

    /// Executes a shell script at the specified path
    /// - Parameter path: Path to the script file
    /// - Throws: SystemActionError if script doesn't exist or execution fails
    public func executeScript(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw SystemActionError.scriptNotFound
        }

        let task = Process()
        task.launchPath = systemPaths.bashPath
        task.arguments = [path]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus != 0 {
                throw SystemActionError.scriptExecutionFailed(exitCode: task.terminationStatus)
            }
        } catch {
            if let systemError = error as? SystemActionError {
                throw systemError
            }
            Log.error("Custom script execution failed", error: error, category: .security)
            throw SystemActionError.scriptExecutionFailed(exitCode: -1)
        }
    }
}
