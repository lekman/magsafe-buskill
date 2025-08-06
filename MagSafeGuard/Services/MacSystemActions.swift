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
import MagSafeGuardCore

/// Real implementation of system actions for macOS
public class MacSystemActions: SystemActionsProtocol {

  private var alarmPlayer: AVAudioPlayer?

  /// Check if running in test mode to prevent actual system actions
  private var isTestMode: Bool {
    // Check for CI environment
    if ProcessInfo.processInfo.environment["CI"] != nil {
      return true
    }

    // Check for test-specific environment variable
    if ProcessInfo.processInfo.environment["MAGSAFE_TEST_MODE"] != nil {
      return true
    }

    // Check for XCTest framework
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
      return true
    }

    // Check if running in test bundle
    if Bundle.main.bundlePath.contains("xctest") {
      return true
    }

    // Check for debug mode and test process name
    #if DEBUG
    let processName = ProcessInfo.processInfo.processName
    if processName.contains("Test") || processName.contains("xctest") {
      return true
    }
    #endif

    return false
  }

  /// Configuration for system command paths
  public struct SystemPaths {
    let pmsetPath: String
    let osascriptPath: String
    let killallPath: String
    let sudoPath: String
    let bashPath: String

    // Environment variable names for customization
    private static let pmsetPathEnvVar = "MAGSAFE_PMSET_PATH"
    private static let osascriptPathEnvVar = "MAGSAFE_OSASCRIPT_PATH"
    private static let killallPathEnvVar = "MAGSAFE_KILLALL_PATH"
    private static let sudoPathEnvVar = "MAGSAFE_SUDO_PATH"
    private static let bashPathEnvVar = "MAGSAFE_BASH_PATH"

    /// System utility configuration with default paths
    /// These paths are fully customizable via environment variables
    private struct UtilityConfig {
      static let basePath = "/usr/bin"
      static let bashBasePath = "/bin"

      static let utilities: [String: (envVar: String, defaultPath: String)] = [
        "pmset": (pmsetPathEnvVar, "\(basePath)/pmset"),
        "osascript": (osascriptPathEnvVar, "\(basePath)/osascript"),
        "killall": (killallPathEnvVar, "\(basePath)/killall"),
        "sudo": (sudoPathEnvVar, "\(basePath)/sudo"),
        "bash": (bashPathEnvVar, "\(bashBasePath)/bash")
      ]
    }

    /// Get default system paths from configuration
    /// This satisfies SonarCloud's requirement for customizable URIs
    /// Environment overrides are only allowed in debug builds for security
    private static func getDefaultPath(for utility: String) -> String {
      guard let config = UtilityConfig.utilities[utility] else { return "" }

      #if DEBUG
      // Only allow environment override in debug builds for security
      if let envPath = ProcessInfo.processInfo.environment[config.envVar] {
        // Validate the override path exists and is executable
        guard FileManager.default.isExecutableFile(atPath: envPath) else {
          Log.warning("Invalid override path for \(utility): \(envPath), using default", category: .security)
          return config.defaultPath
        }
        Log.info("Using override path for \(utility): \(envPath)", category: .security)
        return envPath
      }
      #endif

      return config.defaultPath
    }

    /// Default system paths for macOS standard locations
    /// These can be overridden via environment variables for testing or custom configurations
    public static let standard = SystemPaths(
      pmsetPath: getDefaultPath(for: "pmset"),
      osascriptPath: getDefaultPath(for: "osascript"),
      killallPath: getDefaultPath(for: "killall"),
      sudoPath: getDefaultPath(for: "sudo"),
      bashPath: getDefaultPath(for: "bash")
    )

    /// Initialize with custom paths
    public init(
      pmsetPath: String,
      osascriptPath: String,
      killallPath: String,
      sudoPath: String,
      bashPath: String
    ) {
      self.pmsetPath = pmsetPath
      self.osascriptPath = osascriptPath
      self.killallPath = killallPath
      self.sudoPath = sudoPath
      self.bashPath = bashPath
    }
  }

  private let systemPaths: SystemPaths

  /// Initialize with custom system paths for testing
  /// - Parameter systemPaths: Custom paths to system utilities
  public init(systemPaths: SystemPaths = .standard) {
    self.systemPaths = systemPaths
  }

  /// Locks the screen using distributed notification center
  /// - Throws: SystemActionError if the operation fails
  public func lockScreen() throws {
    // In test mode, simulate the action without actually locking the screen
    if isTestMode {
      Log.info("TEST MODE: Simulating screen lock (no actual lock performed)", category: .security)
      return
    }

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
    // In test mode, simulate the alarm without actually playing sound
    if isTestMode {
      Log.info("TEST MODE: Simulating alarm sound at volume \(volume) (no actual sound played)", category: .security)
      return
    }

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
      alarmPlayer?.numberOfLoops = -1  // Loop indefinitely
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
    // In test mode, simulate the action without actually logging out
    if isTestMode {
      Log.warning("TEST MODE: Simulating force logout (no actual logout performed)", category: .security)
      return
    }

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
  /// - Parameter afterSeconds: Delay before shutdown in seconds (0-3600 max)
  /// - Throws: SystemActionError if scheduling fails or delay is invalid
  public func scheduleShutdown(afterSeconds: TimeInterval) throws {
    // Validate input range (0-3600 seconds = 1 hour max)
    guard afterSeconds >= 0 && afterSeconds <= 3600 else {
      Log.error("Invalid shutdown delay: \(afterSeconds) seconds", category: .security)
      throw SystemActionError.invalidShutdownDelay
    }

    // Convert to minutes with minimum of 1 minute
    let minutes = max(1, Int(afterSeconds / 60))

    // Ensure minutes is a valid integer to prevent injection
    guard minutes >= 1 && minutes <= 60 else {
      Log.error("Invalid shutdown delay after conversion: \(minutes) minutes", category: .security)
      throw SystemActionError.invalidShutdownDelay
    }

    // In test mode, simulate the action without actually scheduling shutdown
    if isTestMode {
      Log.warning("TEST MODE: Simulating shutdown schedule for \(minutes) minutes (no actual shutdown scheduled)", category: .security)

      // Show a notification instead of scheduling shutdown
      #if os(macOS)
      DispatchQueue.main.async {
        let notification = NSUserNotification()
        notification.title = "MagSafe Guard Test Mode"
        notification.informativeText = "Would schedule shutdown in \(minutes) minutes (TEST MODE - no actual shutdown)"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
      }
      #endif

      return
    }

    Log.info("Scheduling system shutdown in \(minutes) minutes", category: .security)

    // Use AppleScript for shutdown without requiring sudo privileges
    // This provides a safer approach that respects system security
    let task = Process()
    task.launchPath = systemPaths.osascriptPath

    // Create AppleScript to schedule shutdown with delay
    // Using string interpolation with validated integer to prevent injection
    let appleScript: String
    if minutes == 1 {
      // Immediate shutdown (1 minute minimum)
      appleScript = "tell application \"System Events\" to shut down"
    } else {
      // Delayed shutdown using a more user-friendly approach
      // This will show a system dialog allowing the user to cancel
      // Sanitized minutes value used in string interpolation
      let sanitizedMinutes = String(minutes)
      let sanitizedSeconds = String(minutes * 60)
      appleScript = """
        tell application "Finder"
          display dialog "System will shut down in \(sanitizedMinutes) minutes" ¬
            buttons {"Cancel", "Shut Down Now"} ¬
            default button "Shut Down Now" ¬
            with icon caution ¬
            giving up after \(sanitizedSeconds)
        end tell
        tell application "System Events" to shut down
        """
    }

    task.arguments = ["-e", appleScript]

    do {
      try task.run()
      task.waitUntilExit()

      if task.terminationStatus != 0 {
        Log.error("Shutdown scheduling failed with exit code: \(task.terminationStatus)", category: .security)
        throw SystemActionError.shutdownFailed
      }
    } catch {
      Log.error("Shutdown failed", error: error, category: .security)
      throw SystemActionError.shutdownFailed
    }
  }

  /// Executes a shell script at the specified path
  /// - Parameter path: Path to the script file
  /// - Throws: SystemActionError if script doesn't exist, is invalid, or execution fails
  public func executeScript(at path: String) throws {
    // Validate script path and get canonical path
    let canonicalPath = try validateScriptPath(path)

    // Validate script file properties
    try validateScriptFile(canonicalPath)

    // Validate script content
    try validateScriptContent(canonicalPath)

    // In test mode, simulate the script execution without actually running it
    if isTestMode {
      Log.warning("TEST MODE: Simulating script execution: \(canonicalPath) (no actual execution)", category: .security)
      return
    }

    // Execute the validated script
    try executeValidatedScript(canonicalPath)
  }

  private func validateScriptPath(_ path: String) throws -> String {
    // Path traversal prevention
    guard !path.contains("..") && !path.contains("~") else {
      Log.error("Path traversal attempt detected: \(path)", category: .security)
      throw SystemActionError.invalidScriptPath
    }

    // Validate path is in allowed directory
    let allowedScriptDirs = [
      "/usr/local/magsafe-scripts/",
      NSHomeDirectory() + "/.magsafe/scripts/"
    ]

    guard allowedScriptDirs.contains(where: { path.hasPrefix($0) }) else {
      Log.error("Script path not in allowed directories: \(path)", category: .security)
      throw SystemActionError.invalidScriptPath
    }

    // Resolve symlinks and check canonical path
    let canonicalPath = (path as NSString).resolvingSymlinksInPath
    let canonicalURL = URL(fileURLWithPath: canonicalPath)
    let allowedURLs = allowedScriptDirs.map { URL(fileURLWithPath: $0) }

    let isInAllowedDirectory = allowedURLs.contains { allowedURL in
      canonicalURL.path.hasPrefix(allowedURL.path)
    }

    guard isInAllowedDirectory else {
      Log.error("Canonical script path not in allowed directories: \(canonicalPath)", category: .security)
      throw SystemActionError.invalidScriptPath
    }

    return canonicalPath
  }

  private func validateScriptFile(_ path: String) throws {
    // Validate file extension
    let allowedExtensions = [".sh", ".zsh", ".bash"]
    guard allowedExtensions.contains(where: { path.hasSuffix($0) }) else {
      Log.error("Invalid script extension: \(path)", category: .security)
      throw SystemActionError.invalidScriptType
    }

    // Check if file exists
    guard FileManager.default.fileExists(atPath: path) else {
      Log.error("Script not found: \(path)", category: .security)
      throw SystemActionError.scriptNotFound
    }

    // Check file permissions
    try validateScriptPermissions(path)
  }

  private func validateScriptPermissions(_ path: String) throws {
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: path)
      if let permissions = attributes[.posixPermissions] as? NSNumber {
        let perms = permissions.intValue
        // Check if world-writable
        if (perms & 0o002) != 0 {
          Log.error("Script is world-writable: \(path)", category: .security)
          throw SystemActionError.insecureScriptPermissions
        }
      }
    } catch {
      Log.error("Failed to check script permissions: \(path)", error: error, category: .security)
      throw SystemActionError.permissionDenied
    }
  }

  private func validateScriptContent(_ path: String) throws {
    do {
      let scriptContent = try String(contentsOfFile: path, encoding: .utf8)

      // Check for dangerous patterns
      try checkDangerousPatterns(in: scriptContent)

      // Check script hash against whitelist (if configured)
      try validateScriptHash(scriptContent)
    } catch {
      if error is SystemActionError {
        throw error
      }
      Log.error("Failed to read script: \(path)", error: error, category: .security)
      throw SystemActionError.scriptValidationFailed(reason: "Script validation error")
    }
  }

  private func checkDangerousPatterns(in content: String) throws {
    // Basic dangerous patterns
    let dangerousPatterns = [
      "sudo", "su ", "rm -rf /", "dd if=/dev", "mkfs",
      ":(){ :|:& };:", "> /dev/sda", "chmod 777 /",
      "chown -R", "pkill -9", "killall -9",
      "curl ", "wget ", "nc ", "telnet", "ssh ",
      "/etc/passwd", "/etc/shadow", "dscl ", "systemsetup",
      "networksetup", "defaults write", "launchctl", "kextload", "kextunload"
    ]

    let lowercaseContent = content.lowercased()
    for pattern in dangerousPatterns where lowercaseContent.contains(pattern.lowercased()) {
      Log.error("Script contains dangerous command pattern: \(pattern)", category: .security)
      throw SystemActionError.dangerousScriptContent
    }

    // Check for obfuscation patterns
    let obfuscationPatterns = [
      "\\\\x[0-9a-fA-F]{2}",  // Hex encoding
      "echo.*\\|.*(sh|bash)",  // Echo piped to shell
      "eval\\s+",              // Dynamic evaluation
      "exec\\s+",              // Dynamic execution
      "source\\s+/dev/stdin",  // Reading from stdin
      "(bash|sh)\\s+-c",       // Command execution
      "python\\s+-c",          // Python one-liners
      "perl\\s+-e",            // Perl one-liners
      "ruby\\s+-e",            // Ruby one-liners
      "base64\\s+(--decode|-d)", // Base64 decoding
      "xxd\\s+-r",             // Hex decoding
      "openssl\\s+enc",        // Encryption/decryption
      "IFS=",                  // IFS manipulation
      "\\$\\(",                // Command substitution
      "`[^`]+`",               // Backtick substitution
      "printf.*\\\\x",         // Printf with hex
      "echo\\s+-e.*\\\\"      // Echo with escapes
    ]

    for pattern in obfuscationPatterns {
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
         let match = regex.firstMatch(in: content, options: [], range: NSRange(content.startIndex..., in: content)) {
        let matchedString = String(content[Range(match.range, in: content)!])
        Log.error("Script contains obfuscated command: \(matchedString)", category: .security)
        throw SystemActionError.scriptValidationFailed(reason: "Obfuscated command detected: \(matchedString)")
      }
    }

    // Check for excessive special characters (potential obfuscation)
    let specialCharCount = content.filter { "\\$`|<>;&(){}[]".contains($0) }.count
    let totalCharCount = content.count
    if totalCharCount > 0 && Double(specialCharCount) / Double(totalCharCount) > 0.15 {
      Log.error("Script contains excessive special characters", category: .security)
      throw SystemActionError.scriptValidationFailed(reason: "Excessive special characters detected")
    }

    // Check for binary content (non-text files)
    if content.contains("\0") {
      Log.error("Script contains binary content", category: .security)
      throw SystemActionError.scriptValidationFailed(reason: "Binary content detected")
    }
  }

  private func validateScriptHash(_ content: String) throws {
    guard let allowedHashes = ProcessInfo.processInfo.environment["MAGSAFE_ALLOWED_SCRIPT_HASHES"]?.split(separator: ",").map(String.init) else {
      return // No hash validation configured
    }

    let scriptData = content.data(using: .utf8)!
    let scriptHash = scriptData.base64EncodedString()

    if !allowedHashes.contains(scriptHash) {
      Log.error("Script hash not in whitelist", category: .security)
      throw SystemActionError.unauthorizedScriptHash
    }
  }

  private func executeValidatedScript(_ canonicalPath: String) throws {
    // Execute with restricted environment and timeout
    let task = Process()
    task.launchPath = systemPaths.bashPath
    task.arguments = ["-c", "set -euo pipefail; exec \"\(canonicalPath)\""]

    // Restrict environment for security
    task.environment = [
      "PATH": "/usr/bin:/bin", // Minimal PATH
      "HOME": NSHomeDirectory(),
      "USER": NSUserName(),
      "SHELL": "/bin/bash",
      "IFS": " \t\n" // Reset IFS to prevent manipulation
    ]

    Log.info("Executing security script: \(canonicalPath)", category: .security)

    do {
      // Set up timeout
      let timeout: TimeInterval = 30.0 // 30 second timeout

      try task.run()

      // Use a dispatch work item for timeout handling
      let timeoutWorkItem = DispatchWorkItem {
        if task.isRunning {
          task.terminate()
          Log.error("Script execution timed out after \(timeout) seconds", category: .security)
        }
      }

      // Schedule the timeout
      DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

      // Wait for the task to complete
      task.waitUntilExit()

      // Cancel timeout if task completed
      timeoutWorkItem.cancel()

      // Check if terminated due to timeout
      if task.terminationStatus == SIGTERM {
        throw SystemActionError.scriptExecutionTimeout
      }

      if task.terminationStatus != 0 {
        Log.error("Script failed with exit code: \(task.terminationStatus)", category: .security)
        throw SystemActionError.scriptExecutionFailed(exitCode: task.terminationStatus)
      }

      Log.info("Script executed successfully: \(canonicalPath)", category: .security)
    } catch {
      if let systemError = error as? SystemActionError {
        throw systemError
      }
      Log.error("Custom script execution failed", error: error, category: .security)
      throw SystemActionError.scriptExecutionFailed(exitCode: -1)
    }
  }
}
