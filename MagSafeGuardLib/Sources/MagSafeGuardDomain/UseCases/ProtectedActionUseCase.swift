//
//  ProtectedActionUseCase.swift
//  MagSafeGuardDomain
//
//  Created on 2025-08-06.
//
//  Clean Architecture Use Case for executing protected security actions.
//  This is pure business logic with no infrastructure dependencies.
//

import Foundation

// MARK: - Use Case Protocol

/// Use case for executing security actions with resource protection
/// Following Clean Architecture principles - pure business logic
public protocol ProtectedActionUseCaseProtocol: Sendable {
    /// Execute a security action with protection
    /// - Parameters:
    ///   - action: The security action to execute
    ///   - completion: Completion handler with result
    func execute(
        action: ProtectedSecurityAction,
        completion: @escaping (Result<Void, SecurityActionError>) -> Void
    ) async
    
    /// Get metrics for a specific action type
    /// - Parameter actionType: The action type to get metrics for
    /// - Returns: Protection metrics
    func getMetrics(for actionType: SecurityActionType) async -> ProtectionMetrics
    
    /// Reset protection for a specific action
    /// - Parameter actionType: The action type to reset
    func resetProtection(for actionType: SecurityActionType) async
}

// MARK: - Domain Models

/// Security action types that can be executed with protection
public enum ProtectedSecurityAction: Equatable, Sendable {
    case lockScreen
    case playAlarm(volume: Float)
    case stopAlarm
    case forceLogout
    case scheduleShutdown(afterSeconds: TimeInterval)
    case executeScript(path: String)
    
    /// Maps to SecurityActionType for protection policies
    public var actionType: SecurityActionType {
        switch self {
        case .lockScreen:
            return .lockScreen
        case .playAlarm, .stopAlarm:
            return .soundAlarm
        case .forceLogout:
            return .forceLogout
        case .scheduleShutdown:
            return .shutdown
        case .executeScript:
            return .customScript
        }
    }
}

// MARK: - Use Case Implementation

/// Implementation of protected action execution
public final class ProtectedActionUseCase: ProtectedActionUseCaseProtocol {
    
    // MARK: - Dependencies (injected via protocols)
    
    private let repository: SecurityActionRepository
    private let protectionPolicy: ResourceProtectionPolicy
    
    // MARK: - Initialization
    
    public init(
        repository: SecurityActionRepository,
        protectionPolicy: ResourceProtectionPolicy
    ) {
        self.repository = repository
        self.protectionPolicy = protectionPolicy
    }
    
    // MARK: - Use Case Execution
    
    public func execute(
        action: ProtectedSecurityAction,
        completion: @escaping (Result<Void, SecurityActionError>) -> Void
    ) async {
        let actionType = action.actionType
        
        do {
            // Check if action is allowed by protection policy
            try await protectionPolicy.validateAction(actionType)
            
            // Execute the action through repository
            try await executeAction(action)
            
            // Record success in protection policy
            await protectionPolicy.recordSuccess(actionType)
            
            completion(.success(()))
        } catch let error as SecurityActionError {
            // Record failure in protection policy
            await protectionPolicy.recordFailure(actionType)
            completion(.failure(error))
        } catch {
            // Handle unexpected errors
            await protectionPolicy.recordFailure(actionType)
            completion(.failure(.systemError(description: error.localizedDescription)))
        }
    }
    
    public func getMetrics(for actionType: SecurityActionType) async -> ProtectionMetrics {
        await protectionPolicy.getMetrics(for: actionType)
    }
    
    public func resetProtection(for actionType: SecurityActionType) async {
        await protectionPolicy.reset(action: actionType)
    }
    
    // MARK: - Private Methods
    
    private func executeAction(_ action: ProtectedSecurityAction) async throws {
        switch action {
        case .lockScreen:
            try await repository.lockScreen()
        case .playAlarm(let volume):
            try await repository.playAlarm(volume: volume)
        case .stopAlarm:
            await repository.stopAlarm()
        case .forceLogout:
            try await repository.forceLogout()
        case .scheduleShutdown(let afterSeconds):
            try await repository.scheduleShutdown(afterSeconds: afterSeconds)
        case .executeScript(let path):
            try await repository.executeScript(at: path)
        }
    }
}

// MARK: - Factory

/// Factory for creating protected action use cases
public struct ProtectedActionUseCaseFactory {
    /// Creates a use case with the given dependencies
    public static func make(
        repository: SecurityActionRepository,
        protectionPolicy: ResourceProtectionPolicy
    ) -> ProtectedActionUseCaseProtocol {
        ProtectedActionUseCase(
            repository: repository,
            protectionPolicy: protectionPolicy
        )
    }
}