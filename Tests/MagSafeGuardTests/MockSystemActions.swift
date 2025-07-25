//
//  MockSystemActions.swift
//  MagSafeGuardTests
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
    var playAlarmCalled = false
    var playAlarmVolume: Float?
    var stopAlarmCalled = false
    var forceLogoutCalled = false
    var scheduleShutdownCalled = false
    var shutdownDelaySeconds: TimeInterval?
    var executeScriptCalled = false
    var executedScriptPath: String?
    
    // Control whether actions should fail
    var shouldFailScreenLock = false
    var shouldFailAlarm = false
    var shouldFailLogout = false
    var shouldFailShutdown = false
    var shouldFailScript = false
    var scriptExitCode: Int32 = 0
    
    // Reset method for test setup
    func reset() {
        lockScreenCalled = false
        playAlarmCalled = false
        playAlarmVolume = nil
        stopAlarmCalled = false
        forceLogoutCalled = false
        scheduleShutdownCalled = false
        shutdownDelaySeconds = nil
        executeScriptCalled = false
        executedScriptPath = nil
        
        shouldFailScreenLock = false
        shouldFailAlarm = false
        shouldFailLogout = false
        shouldFailShutdown = false
        shouldFailScript = false
        scriptExitCode = 0
    }
    
    func lockScreen() throws {
        lockScreenCalled = true
        if shouldFailScreenLock {
            throw SystemActionError.screenLockFailed
        }
    }
    
    func playAlarm(volume: Float) throws {
        playAlarmCalled = true
        playAlarmVolume = volume
        if shouldFailAlarm {
            throw SystemActionError.alarmPlaybackFailed
        }
    }
    
    func stopAlarm() {
        stopAlarmCalled = true
    }
    
    func forceLogout() throws {
        forceLogoutCalled = true
        if shouldFailLogout {
            throw SystemActionError.logoutFailed
        }
    }
    
    func scheduleShutdown(afterSeconds: TimeInterval) throws {
        scheduleShutdownCalled = true
        shutdownDelaySeconds = afterSeconds
        if shouldFailShutdown {
            throw SystemActionError.shutdownFailed
        }
    }
    
    func executeScript(at path: String) throws {
        executeScriptCalled = true
        executedScriptPath = path
        
        // Check if file exists for realistic behavior
        if !FileManager.default.fileExists(atPath: path) {
            throw SystemActionError.scriptNotFound
        }
        
        if shouldFailScript {
            if scriptExitCode != 0 {
                throw SystemActionError.scriptExecutionFailed(exitCode: scriptExitCode)
            } else {
                throw SystemActionError.scriptExecutionFailed(exitCode: 1)
            }
        }
    }
}