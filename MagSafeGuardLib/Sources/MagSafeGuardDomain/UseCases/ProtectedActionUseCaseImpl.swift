//
//  ProtectedActionUseCaseImpl.swift
//  MagSafeGuardDomain
//
//  Created on 2025-08-06.
//
//  Clean Architecture Use Case implementation for executing protected security actions.
//  This is pure business logic with no infrastructure dependencies.
//

import Foundation

// MARK: - Use Case Implementation

/// Implementation of protected action execution
public final class ProtectedActionUseCaseImpl: ProtectedActionUseCase {
    
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
    ) -> ProtectedActionUseCase {
        ProtectedActionUseCaseImpl(
            repository: repository,
            protectionPolicy: protectionPolicy
        )
    }
}