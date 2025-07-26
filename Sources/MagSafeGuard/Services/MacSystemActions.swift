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

        public static let `default` = SystemPaths(
            pmsetPath: "/usr/bin/pmset",
            osascriptPath: "/usr/bin/osascript",
            killallPath: "/usr/bin/killall",
            sudoPath: "/usr/bin/sudo",
            bashPath: "/bin/bash"
        )
    }

    private let systemPaths: SystemPaths

    public init(systemPaths: SystemPaths = .default) {
        self.systemPaths = systemPaths
    }

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
            print("[MacSystemActions] Screen lock failed: \(error)")
            throw SystemActionError.screenLockFailed
        }
    }

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
            print("[MacSystemActions] Failed to play alarm sound: \(error)")
            // Fallback to system beep
            NSSound.beep()
            throw SystemActionError.alarmPlaybackFailed
        }
    }

    public func stopAlarm() {
        alarmPlayer?.stop()
        alarmPlayer = nil
    }

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
            print("[MacSystemActions] Force logout failed: \(error)")
            throw SystemActionError.logoutFailed
        }
    }

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
            print("[MacSystemActions] Shutdown failed: \(error)")
            throw SystemActionError.shutdownFailed
        }
    }

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
            print("[MacSystemActions] Custom script execution failed: \(error)")
            throw SystemActionError.scriptExecutionFailed(exitCode: -1)
        }
    }
}
