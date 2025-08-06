//
//  ResourceProtectionPolicyAdapter.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//
//  Adapter to bridge ResourceProtector with Clean Architecture policy
//

import Foundation
import MagSafeGuardDomain

/// Adapts ResourceProtector to conform to ResourceProtectionPolicy protocol
/// This follows the Adapter pattern to integrate infrastructure with domain layer
public final class ResourceProtectionPolicyAdapter: ResourceProtectionPolicy {

    // MARK: - Properties

    private let resourceProtector: ResourceProtector

    // MARK: - Initialization

    /// Initialize with a resource protector instance
    public init(resourceProtector: ResourceProtector) {
        self.resourceProtector = resourceProtector
    }

    /// Convenience initializer with configuration
    public convenience init(config: ResourceProtectorConfig = .default) {
        let protector = ResourceProtector(
            rateLimiterConfig: config.rateLimiter,
            circuitBreakerConfig: config.circuitBreaker
        )
        self.init(resourceProtector: protector)
    }

    // MARK: - ResourceProtectionPolicy Implementation

    /// Validate if an action can proceed through resource protection
    public func validateAction(_ action: SecurityActionType) async throws {
        let actionKey = mapActionTypeToKey(action)

        do {
            _ = try await resourceProtector.checkAction(actionKey)
        } catch let error as ResourceProtectionError {
            // Map infrastructure errors to domain errors
            throw mapProtectionError(error, for: action)
        }
    }

    /// Record successful action execution
    public func recordSuccess(_ action: SecurityActionType) async {
        let actionKey = mapActionTypeToKey(action)
        await resourceProtector.recordSuccess(actionKey)
    }

    /// Record failed action execution
    public func recordFailure(_ action: SecurityActionType) async {
        let actionKey = mapActionTypeToKey(action)
        await resourceProtector.recordFailure(actionKey)
    }

    /// Get protection metrics for a specific action
    public func getMetrics(for action: SecurityActionType) async -> ProtectionMetrics {
        let actionKey = mapActionTypeToKey(action)
        let rawMetrics = await resourceProtector.getMetrics(for: actionKey)

        return ProtectionMetrics(
            totalAttempts: rawMetrics["totalAttempts"] as? Int ?? 0,
            successfulExecutions: rawMetrics["successfulExecutions"] as? Int ?? 0,
            rateLimitedAttempts: rawMetrics["rateLimitedAttempts"] as? Int ?? 0,
            circuitBreakerRejections: rawMetrics["circuitBreakerRejections"] as? Int ?? 0,
            lastAttemptTime: Date(timeIntervalSince1970: rawMetrics["lastAttemptTime"] as? TimeInterval ?? 0),
            successRate: rawMetrics["successRate"] as? Double ?? 0.0
        )
    }
    
    /// Reset protection for specific action
    public func reset(action: SecurityActionType) async {
        let actionKey = mapActionTypeToKey(action)
        await resourceProtector.reset(action: actionKey)
    }

    // MARK: - Private Methods

    private func mapActionTypeToKey(_ action: SecurityActionType) -> String {
        switch action {
        case .lockScreen:
            return "lockScreen"
        case .soundAlarm:
            return "playAlarm"
        case .forceLogout:
            return "forceLogout"
        case .shutdown:
            return "shutdown"
        case .customScript:
            return "executeScript"
        @unknown default:
            return "unknown"
        }
    }

    private func mapProtectionError(_ error: ResourceProtectionError, for action: SecurityActionType) -> SecurityActionError {
        switch error {
        case .rateLimited(_, let retryAfter):
            return .actionFailed(
                type: action,
                reason: "Action rate limited. Retry after \(Int(retryAfter)) seconds"
            )
        case .circuitOpen:
            return .actionFailed(
                type: action,
                reason: "Service temporarily unavailable due to recent failures"
            )
        case .resourceExhausted:
            return .actionFailed(
                type: action,
                reason: "System resources exhausted. Please wait before retrying"
            )
        case .protectionDisabled:
            return .systemError(description: "Resource protection is disabled")
        }
    }
}
