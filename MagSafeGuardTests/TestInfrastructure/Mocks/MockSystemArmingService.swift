//
//  MockSystemArmingService.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Mock implementation of SystemArmingService for testing.
//  Provides controllable system arming behavior for unit tests.
//

import Foundation
@testable import MagSafeGuard

/// Mock implementation of SystemArmingService for testing.
/// Allows full control over system arming behavior in tests.
public actor MockSystemArmingService: SystemArmingService {
    
    // MARK: - Properties
    
    /// Current armed state
    public var isArmed = false
    
    /// Error to throw on arm
    public var armError: Error?
    
    /// Track method calls
    public private(set) var isArmedCalls = 0
    public private(set) var armCalls = 0
    
    /// Arm history for verification
    public private(set) var armHistory: [Date] = []
    
    /// Delay for operations
    public var operationDelay: TimeInterval = 0
    
    /// Callback for arm events
    public var onArm: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize mock service
    public init() {}
    
    // MARK: - Configuration Methods
    
    /// Configure armed state
    /// - Parameter armed: Whether system is armed
    public func configureArmedState(_ armed: Bool) {
        isArmed = armed
    }
    
    /// Configure to fail on arm
    /// - Parameter error: Error to throw
    public func configureArmFailure(_ error: Error? = nil) {
        armError = error ?? MockError.customError("Failed to arm system")
    }
    
    /// Reset all mock state
    public func reset() {
        isArmed = false
        armError = nil
        isArmedCalls = 0
        armCalls = 0
        armHistory = []
        operationDelay = 0
        onArm = nil
    }
    
    // MARK: - SystemArmingService Implementation
    
    public func isArmed() async -> Bool {
        isArmedCalls += 1
        
        if operationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        return isArmed
    }
    
    public func arm() async throws {
        armCalls += 1
        
        if operationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if let error = armError {
            throw error
        }
        
        isArmed = true
        armHistory.append(Date())
        onArm?()
    }
}

// MARK: - Test Helpers

extension MockSystemArmingService {
    
    /// Verify system was armed within time window
    /// - Parameter timeWindow: Time window in seconds
    /// - Returns: True if armed within window
    public func verifyArmedWithin(seconds timeWindow: TimeInterval) -> Bool {
        guard let lastArm = armHistory.last else { return false }
        return Date().timeIntervalSince(lastArm) <= timeWindow
    }
    
    /// Get number of arm attempts
    /// - Returns: Number of times arm was called
    public func getArmAttempts() -> Int {
        armCalls
    }
    
    /// Simulate disarm (for testing re-arm scenarios)
    public func simulateDisarm() {
        isArmed = false
    }
    
    /// Configure for already armed scenario
    public func configureAlreadyArmed() {
        isArmed = true
        armError = MockError.customError("System already armed")
    }
}