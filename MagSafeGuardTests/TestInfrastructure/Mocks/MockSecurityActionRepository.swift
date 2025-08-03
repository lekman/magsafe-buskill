//
//  MockSecurityActionRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of SecurityActionRepository for testing.
//  Provides controllable security action behavior for unit tests.
//

import Foundation
@testable import MagSafeGuard

/// Mock implementation of SecurityActionRepository for testing.
/// Allows full control over security action behavior in tests.
public actor MockSecurityActionRepository: SecurityActionRepository {
    
    // MARK: - Properties
    
    /// Track method calls
    public private(set) var lockScreenCalls = 0
    public private(set) var playAlarmCalls = 0
    public private(set) var stopAlarmCalls = 0
    public private(set) var forceLogoutCalls = 0
    public private(set) var scheduleShutdownCalls = 0
    public private(set) var executeScriptCalls = 0
    
    /// Track parameters
    public private(set) var lastAlarmVolume: Float?
    public private(set) var lastShutdownDelay: TimeInterval?
    public private(set) var lastScriptPath: String?
    
    /// Errors to throw for each action
    public var lockScreenError: Error?
    public var playAlarmError: Error?
    public var forceLogoutError: Error?
    public var scheduleShutdownError: Error?
    public var executeScriptError: Error?
    
    /// Delays for each action (to simulate execution time)
    public var lockScreenDelay: TimeInterval = 0
    public var playAlarmDelay: TimeInterval = 0
    public var forceLogoutDelay: TimeInterval = 0
    public var scheduleShutdownDelay: TimeInterval = 0
    public var executeScriptDelay: TimeInterval = 0
    
    /// State tracking
    public private(set) var isAlarmPlaying = false
    public private(set) var isScreenLocked = false
    public private(set) var isShutdownScheduled = false
    public private(set) var executedScripts: [String] = []
    
    /// Behavior configuration
    public var shouldFailAfterDelay = false
    public var failureDelay: TimeInterval = 0.5
    
    // MARK: - Initialization
    
    /// Initialize mock repository
    public init() {}
    
    // MARK: - Configuration Methods
    
    /// Configure all actions to succeed
    public func configureSuccess() {
        lockScreenError = nil
        playAlarmError = nil
        forceLogoutError = nil
        scheduleShutdownError = nil
        executeScriptError = nil
    }
    
    /// Configure specific action to fail
    /// - Parameters:
    ///   - action: Action type to fail
    ///   - error: Error to throw
    public func configureFailure(for action: SecurityActionType, error: Error? = nil) {
        let actionError = error ?? SecurityActionError.actionFailed(
            type: action,
            reason: "Mock failure"
        )
        
        switch action {
        case .lockScreen:
            lockScreenError = actionError
        case .soundAlarm:
            playAlarmError = actionError
        case .forceLogout:
            forceLogoutError = actionError
        case .shutdown:
            scheduleShutdownError = actionError
        case .customScript:
            executeScriptError = actionError
        }
    }
    
    /// Configure delays for realistic testing
    public func configureRealisticDelays() {
        lockScreenDelay = 0.1
        playAlarmDelay = 0.05
        forceLogoutDelay = 0.2
        scheduleShutdownDelay = 0.15
        executeScriptDelay = 0.3
    }
    
    /// Reset all mock state
    public func reset() {
        lockScreenCalls = 0
        playAlarmCalls = 0
        stopAlarmCalls = 0
        forceLogoutCalls = 0
        scheduleShutdownCalls = 0
        executeScriptCalls = 0
        
        lastAlarmVolume = nil
        lastShutdownDelay = nil
        lastScriptPath = nil
        
        lockScreenError = nil
        playAlarmError = nil
        forceLogoutError = nil
        scheduleShutdownError = nil
        executeScriptError = nil
        
        lockScreenDelay = 0
        playAlarmDelay = 0
        forceLogoutDelay = 0
        scheduleShutdownDelay = 0
        executeScriptDelay = 0
        
        isAlarmPlaying = false
        isScreenLocked = false
        isShutdownScheduled = false
        executedScripts = []
        
        shouldFailAfterDelay = false
        failureDelay = 0.5
    }
    
    // MARK: - SecurityActionRepository Implementation
    
    public func lockScreen() async throws {
        lockScreenCalls += 1
        
        if lockScreenDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(lockScreenDelay * 1_000_000_000))
        }
        
        if shouldFailAfterDelay {
            try await Task.sleep(nanoseconds: UInt64(failureDelay * 1_000_000_000))
            throw SecurityActionError.actionFailed(type: .lockScreen, reason: "Failed after delay")
        }
        
        if let error = lockScreenError {
            throw error
        }
        
        isScreenLocked = true
    }
    
    public func playAlarm(volume: Float) async throws {
        playAlarmCalls += 1
        lastAlarmVolume = volume
        
        if playAlarmDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(playAlarmDelay * 1_000_000_000))
        }
        
        if let error = playAlarmError {
            throw error
        }
        
        isAlarmPlaying = true
    }
    
    public func stopAlarm() async {
        stopAlarmCalls += 1
        isAlarmPlaying = false
    }
    
    public func forceLogout() async throws {
        forceLogoutCalls += 1
        
        if forceLogoutDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(forceLogoutDelay * 1_000_000_000))
        }
        
        if let error = forceLogoutError {
            throw error
        }
        
        // Simulate logout by locking screen
        isScreenLocked = true
    }
    
    public func scheduleShutdown(afterSeconds: TimeInterval) async throws {
        scheduleShutdownCalls += 1
        lastShutdownDelay = afterSeconds
        
        if scheduleShutdownDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(scheduleShutdownDelay * 1_000_000_000))
        }
        
        if let error = scheduleShutdownError {
            throw error
        }
        
        isShutdownScheduled = true
    }
    
    public func executeScript(at path: String) async throws {
        executeScriptCalls += 1
        lastScriptPath = path
        
        if executeScriptDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(executeScriptDelay * 1_000_000_000))
        }
        
        // Validate script path
        if path.isEmpty {
            throw SecurityActionError.scriptNotFound(path: path)
        }
        
        if let error = executeScriptError {
            throw error
        }
        
        executedScripts.append(path)
    }
}

// MARK: - Test Helpers

extension MockSecurityActionRepository {
    
    /// Verify that specific actions were called
    /// - Parameter actions: Actions to verify
    /// - Returns: True if all actions were called
    public func verifyActionsCalled(_ actions: Set<SecurityActionType>) -> Bool {
        for action in actions {
            switch action {
            case .lockScreen:
                if lockScreenCalls == 0 { return false }
            case .soundAlarm:
                if playAlarmCalls == 0 { return false }
            case .forceLogout:
                if forceLogoutCalls == 0 { return false }
            case .shutdown:
                if scheduleShutdownCalls == 0 { return false }
            case .customScript:
                if executeScriptCalls == 0 { return false }
            }
        }
        return true
    }
    
    /// Get total number of action calls
    /// - Returns: Total calls across all actions
    public func getTotalActionCalls() -> Int {
        lockScreenCalls + playAlarmCalls + forceLogoutCalls + 
        scheduleShutdownCalls + executeScriptCalls
    }
    
    /// Verify alarm was played with correct volume
    /// - Parameter expectedVolume: Expected volume
    /// - Returns: True if matches
    public func verifyAlarmVolume(_ expectedVolume: Float) -> Bool {
        guard let volume = lastAlarmVolume else { return false }
        return abs(volume - expectedVolume) < 0.001
    }
    
    /// Verify shutdown was scheduled with correct delay
    /// - Parameter expectedDelay: Expected delay
    /// - Returns: True if matches
    public func verifyShutdownDelay(_ expectedDelay: TimeInterval) -> Bool {
        guard let delay = lastShutdownDelay else { return false }
        return abs(delay - expectedDelay) < 0.001
    }
    
    /// Configure for permission denied scenario
    /// - Parameter action: Action to deny
    public func configurePermissionDenied(for action: SecurityActionType) {
        configureFailure(
            for: action,
            error: SecurityActionError.permissionDenied(action: action)
        )
    }
    
    /// Configure for system error scenario
    /// - Parameter description: Error description
    public func configureSystemError(_ description: String = "System error") {
        let error = SecurityActionError.systemError(description: description)
        lockScreenError = error
        playAlarmError = error
        forceLogoutError = error
        scheduleShutdownError = error
        executeScriptError = error
    }
}