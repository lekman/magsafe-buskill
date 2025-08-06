//
//  ProtectedActionProtocols.swift
//  MagSafeGuardDomain
//
//  Created on 2025-08-06.
//
//  Clean Architecture protocols for executing protected security actions.
//

import Foundation

// MARK: - Use Case Protocol

/// Use case for executing security actions with resource protection
/// Following Clean Architecture principles - pure business logic
public protocol ProtectedActionUseCase: Sendable {
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