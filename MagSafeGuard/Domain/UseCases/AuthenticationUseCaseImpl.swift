//
//  AuthenticationUseCaseImpl.swift
//  MagSafe Guard
//
//  Implementation of authentication use case with pure business logic.
//  This class contains no system dependencies and is fully testable.
//

import Foundation

/// Concrete implementation of AuthenticationUseCase
public final class AuthenticationUseCaseImpl: AuthenticationUseCase {

    // MARK: - Properties

    private let repository: AuthenticationRepository
    private let securityConfig: AuthenticationSecurityConfig
    private let stateManager: AuthenticationStateManager

    // MARK: - Initialization

    public init(
        repository: AuthenticationRepository,
        securityConfig: AuthenticationSecurityConfig = .default,
        stateManager: AuthenticationStateManager = InMemoryAuthenticationStateManager()
    ) {
        self.repository = repository
        self.securityConfig = securityConfig
        self.stateManager = stateManager
    }

    // MARK: - AuthenticationUseCase Implementation

    public func authenticate(reason: String, policy: AuthenticationPolicy) async -> AuthenticationResult {
        // Validate request
        let validationResult = validateAuthenticationRequest(reason: reason)
        if case .failure(let error) = validationResult {
            await stateManager.recordAttempt(
                AuthenticationAttempt(
                    timestamp: Date(),
                    success: false,
                    method: nil,
                    reason: reason
                )
            )
            return .failure(error)
        }

        // Check rate limiting
        if let rateLimitDate = await checkRateLimit() {
            return .failure(.rateLimited(untilDate: rateLimitDate))
        }

        // Check cached authentication if policy allows
        if policy.requireRecentAuthentication,
           let lastAuth = await stateManager.getLastAuthentication(),
           Date().timeIntervalSince(lastAuth.authenticatedAt) < policy.cacheDuration {
            return .success(
                AuthenticationSuccess(
                    authenticatedAt: lastAuth.authenticatedAt,
                    method: .cached,
                    cached: true
                )
            )
        }

        // Create authentication request
        let request = AuthenticationRequest(
            reason: reason,
            policy: policy,
            timestamp: Date()
        )

        // Perform authentication
        let result = await repository.authenticate(request: request)

        // Record attempt
        let attempt = AuthenticationAttempt(
            timestamp: Date(),
            success: result.isSuccess,
            method: extractMethod(from: result),
            reason: reason
        )
        await stateManager.recordAttempt(attempt)

        // Update last authentication on success
        if case .success(let success) = result {
            await stateManager.updateLastAuthentication(success)
        }

        return result
    }

    public func checkBiometricAvailability() async -> BiometricAvailability {
        return await repository.isBiometricAvailable()
    }

    public func clearAuthenticationCache() async {
        await stateManager.clearCache()
    }

    public func getLastAuthentication() async -> AuthenticationSuccess? {
        return await stateManager.getLastAuthentication()
    }

    // MARK: - Private Methods

    private func validateAuthenticationRequest(reason: String) -> AuthenticationResult {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedReason.isEmpty {
            return .failure(.invalidRequest(reason: "Authentication reason cannot be empty"))
        }

        if trimmedReason.count > securityConfig.maxReasonLength {
            return .failure(.invalidRequest(reason: "Authentication reason is too long"))
        }

        return .success(
            AuthenticationSuccess(
                authenticatedAt: Date(),
                method: .cached,
                cached: false
            )
        )
    }

    private func checkRateLimit() async -> Date? {
        let recentAttempts = await stateManager.getRecentAttempts(
            since: Date().addingTimeInterval(-securityConfig.rateLimitDuration)
        )

        let failedAttempts = recentAttempts.filter { !$0.success }.count

        if failedAttempts >= securityConfig.maxFailedAttempts {
            // Calculate when rate limit expires
            if let lastFailedAttempt = recentAttempts.filter({ !$0.success }).last {
                return lastFailedAttempt.timestamp.addingTimeInterval(securityConfig.rateLimitDuration)
            }
        }

        return nil
    }

    private func extractMethod(from result: AuthenticationResult) -> AuthenticationMethod? {
        if case .success(let success) = result {
            return success.method
        }
        return nil
    }
}

/// Concrete implementation of AuthenticationStateUseCase
public final class AuthenticationStateUseCaseImpl: AuthenticationStateUseCase {

    private let stateManager: AuthenticationStateManager
    private let repository: AuthenticationRepository

    public init(
        stateManager: AuthenticationStateManager,
        repository: AuthenticationRepository
    ) {
        self.stateManager = stateManager
        self.repository = repository
    }

    public func isAuthenticated(policy: AuthenticationPolicy) async -> Bool {
        guard let lastAuth = await stateManager.getLastAuthentication() else {
            return false
        }

        let timeSinceAuth = Date().timeIntervalSince(lastAuth.authenticatedAt)
        return timeSinceAuth < policy.cacheDuration
    }

    public func invalidateAuthentication() async {
        await repository.invalidateAuthentication()
        await stateManager.clearCache()
    }

    public func getAuthenticationHistory() async -> [AuthenticationAttempt] {
        return await stateManager.getAllAttempts()
    }
}

// MARK: - State Management

/// Protocol for managing authentication state
public protocol AuthenticationStateManager {
    func recordAttempt(_ attempt: AuthenticationAttempt) async
    func getRecentAttempts(since date: Date) async -> [AuthenticationAttempt]
    func getAllAttempts() async -> [AuthenticationAttempt]
    func updateLastAuthentication(_ success: AuthenticationSuccess) async
    func getLastAuthentication() async -> AuthenticationSuccess?
    func clearCache() async
}

/// In-memory implementation of authentication state manager
public actor InMemoryAuthenticationStateManager: AuthenticationStateManager {

    private var attempts: [AuthenticationAttempt] = []
    private var lastAuthentication: AuthenticationSuccess?
    private let maxHistorySize = 100

    public init() {}

    public func recordAttempt(_ attempt: AuthenticationAttempt) {
        attempts.append(attempt)

        // Limit history size
        if attempts.count > maxHistorySize {
            attempts.removeFirst(attempts.count - maxHistorySize)
        }
    }

    public func getRecentAttempts(since date: Date) -> [AuthenticationAttempt] {
        return attempts.filter { $0.timestamp >= date }
    }

    public func getAllAttempts() -> [AuthenticationAttempt] {
        return attempts
    }

    public func updateLastAuthentication(_ success: AuthenticationSuccess) {
        lastAuthentication = success
    }

    public func getLastAuthentication() -> AuthenticationSuccess? {
        return lastAuthentication
    }

    public func clearCache() {
        lastAuthentication = nil
    }
}
