//
//  MockSystemActions.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  Mock implementation of system actions for testing.
//

import Foundation

@testable import MagSafeGuard

/// Mock implementation of system actions for testing
class MockSystemActions: SystemActionsProtocol {

  // Track which actions were called
  var lockScreenCalled = false
  var lockScreenCallCount = 0
  var playAlarmCalled = false
  var playAlarmVolume: Float?
  var lastAlarmVolume: Float?
  var stopAlarmCalled = false
  var forceLogoutCalled = false
  var forceLogoutCallCount = 0
  var scheduleShutdownCalled = false
  var shutdownDelaySeconds: TimeInterval?
  var lastShutdownDelay: TimeInterval?
  var executeScriptCalled = false
  var executedScriptPath: String?
  var lastScriptPath: String?

  // Control whether actions should succeed/fail
  var lockScreenShouldSucceed = true
  var playAlarmShouldSucceed = true
  var forceLogoutShouldSucceed = true
  var scheduleShutdownShouldSucceed = true
  var executeScriptShouldSucceed = true

  // Control whether actions should fail (legacy)
  var shouldFailScreenLock = false
  var shouldFailAlarm = false
  var shouldFailLogout = false
  var shouldFailShutdown = false
  var shouldFailScript = false
  var scriptExitCode: Int32 = 0

  // Errors to throw
  var lockScreenError: Error?

  // Reset method for test setup
  func reset() {
    lockScreenCalled = false
    lockScreenCallCount = 0
    playAlarmCalled = false
    playAlarmVolume = nil
    lastAlarmVolume = nil
    stopAlarmCalled = false
    forceLogoutCalled = false
    forceLogoutCallCount = 0
    scheduleShutdownCalled = false
    shutdownDelaySeconds = nil
    lastShutdownDelay = nil
    executeScriptCalled = false
    executedScriptPath = nil
    lastScriptPath = nil

    lockScreenShouldSucceed = true
    playAlarmShouldSucceed = true
    forceLogoutShouldSucceed = true
    scheduleShutdownShouldSucceed = true
    executeScriptShouldSucceed = true

    shouldFailScreenLock = false
    shouldFailAlarm = false
    shouldFailLogout = false
    shouldFailShutdown = false
    shouldFailScript = false
    scriptExitCode = 0

    lockScreenError = nil
  }

  func lockScreen() throws {
    lockScreenCalled = true
    lockScreenCallCount += 1

    if let error = lockScreenError {
      throw error
    }

    if !lockScreenShouldSucceed || shouldFailScreenLock {
      throw SystemActionError.screenLockFailed
    }
  }

  func playAlarm(volume: Float) throws {
    playAlarmCalled = true
    playAlarmVolume = volume
    lastAlarmVolume = volume

    if !playAlarmShouldSucceed || shouldFailAlarm {
      throw SystemActionError.alarmPlaybackFailed
    }
  }

  func stopAlarm() {
    stopAlarmCalled = true
  }

  func forceLogout() throws {
    forceLogoutCalled = true
    forceLogoutCallCount += 1

    if !forceLogoutShouldSucceed || shouldFailLogout {
      throw SystemActionError.logoutFailed
    }
  }

  func scheduleShutdown(afterSeconds: TimeInterval) throws {
    scheduleShutdownCalled = true
    shutdownDelaySeconds = afterSeconds
    lastShutdownDelay = afterSeconds

    if !scheduleShutdownShouldSucceed || shouldFailShutdown {
      throw SystemActionError.shutdownFailed
    }
  }

  func executeScript(at path: String) throws {
    executeScriptCalled = true
    executedScriptPath = path
    lastScriptPath = path

    // Check if file exists for realistic behavior
    if !FileManager.default.fileExists(atPath: path) {
      throw SystemActionError.scriptNotFound
    }

    if !executeScriptShouldSucceed || shouldFailScript {
      if scriptExitCode != 0 {
        throw SystemActionError.scriptExecutionFailed(exitCode: scriptExitCode)
      } else {
        throw SystemActionError.scriptExecutionFailed(exitCode: 1)
      }
    }
  }
}
