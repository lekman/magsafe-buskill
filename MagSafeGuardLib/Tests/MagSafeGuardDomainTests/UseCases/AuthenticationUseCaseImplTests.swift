//
//  AuthenticationUseCaseImplTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-04.
//
//  Tests for AuthenticationUseCaseImpl to achieve 95%+ coverage

import Foundation
@testable import MagSafeGuardDomain
import Testing

extension AuthenticationUseCaseImplTests {
    // Test-specific error for mocking
    enum TestAuthenticationError: LocalizedError, Equatable {
        case biometricUnavailable
        case authenticationFailed
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .biometricUnavailable:
                return "Biometric authentication unavailable"
            case .authenticationFailed:
                return "Authentication failed"
            case .invalidCredentials:
                return "Invalid credentials"
            }
        }
    }
}

@Suite("AuthenticationUseCaseImpl Tests")
struct AuthenticationUseCaseImplTests {

    // MARK: - Mock Dependencies

    private class MockAuthenticationRepository: AuthenticationRepository {
        private let shouldFail: Bool
        private let biometricAvailable: Bool
        private let authenticationMethod: AuthenticationMethod
        private let simulateDelay: Bool

        init(
            shouldFail: Bool = false,
            biometricAvailable: Bool = true,
            authenticationMethod: AuthenticationMethod = .touchID,
            simulateDelay: Bool = false
        ) {
            self.shouldFail = shouldFail
            self.biometricAvailable = biometricAvailable
            self.authenticationMethod = authenticationMethod
            self.simulateDelay = simulateDelay
        }

        func authenticate(request: AuthenticationRequest) async -> AuthenticationResult {
            if simulateDelay {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            if shouldFail {
                return .failure(.systemError(description: "Mock authentication failed"))
            }

            return .success(
                AuthenticationSuccess(
                    authenticatedAt: Date(),
                    method: authenticationMethod,
                    cached: false
                )
            )
        }

        func isBiometricAvailable() async -> BiometricAvailability {
            if biometricAvailable {
                return BiometricAvailability(
                    isAvailable: true,
                    biometricType: .touchID,
                    unavailableReason: nil
                )
            } else {
                return BiometricAvailability(
                    isAvailable: false,
                    biometricType: nil,
                    unavailableReason: "Biometry not available"
                )
            }
        }

        func invalidateAuthentication() async {
            // Mock implementation - no-op
        }
    }

    private actor MockAuthenticationStateManager: AuthenticationStateManager {
        private var attempts: [AuthenticationAttempt] = []
        private var lastAuthentication: AuthenticationSuccess?

        func recordAttempt(_ attempt: AuthenticationAttempt) {
            attempts.append(attempt)
        }

        func getRecentAttempts(since date: Date) -> [AuthenticationAttempt] {
            return attempts.filter { $0.timestamp >= date }
        }

        func getAllAttempts() -> [AuthenticationAttempt] {
            return attempts
        }

        func updateLastAuthentication(_ success: AuthenticationSuccess) {
            lastAuthentication = success
        }

        func getLastAuthentication() -> AuthenticationSuccess? {
            return lastAuthentication
        }

        func clearCache() {
            lastAuthentication = nil
        }

        // Test helpers
        func setLastAuthentication(_ auth: AuthenticationSuccess?) {
            lastAuthentication = auth
        }

        func addFailedAttempts(count: Int, at date: Date = Date()) {
            for i in 0..<count {
                let attempt = AuthenticationAttempt(
                    timestamp: date.addingTimeInterval(TimeInterval(i)),
                    success: false,
                    method: nil,
                    reason: "Test failed attempt \(i)"
                )
                attempts.append(attempt)
            }
        }
    }

    // MARK: - AuthenticationUseCaseImpl Tests

    @Test("AuthenticationUseCaseImpl initialization")
    func authenticationUseCaseImplInitialization() {
        let repository = MockAuthenticationRepository()
        let config = AuthenticationSecurityConfig.default
        let stateManager = MockAuthenticationStateManager()

        let useCase = AuthenticationUseCaseImpl(
            repository: repository,
            securityConfig: config,
            stateManager: stateManager
        )

        // Test that initialization doesn't fail
        #expect(useCase != nil)
    }

    @Test("AuthenticationUseCaseImpl initialization with custom config")
    func initializationWithCustomConfig() {
        let repository = MockAuthenticationRepository()
        let customConfig = AuthenticationSecurityConfig(
            maxFailedAttempts: 3,
            rateLimitDuration: 900, // 15 minutes
            maxReasonLength: 200
        )
        let stateManager = MockAuthenticationStateManager()

        let useCase = AuthenticationUseCaseImpl(
            repository: repository,
            securityConfig: customConfig,
            stateManager: stateManager
        )

        // Test that initialization doesn't fail
    }

    // MARK: - Authentication Tests

    @Test("Successful authentication")
    func successfulAuthentication() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "Test authentication", policy: policy)

        guard case .success(let success) = result else {
            #expect(Bool(false), "Authentication should have succeeded")
            return
        }

        #expect(success.method == .touchID)
        #expect(success.cached == false)

        // Verify attempt was recorded
        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 1)
        #expect(attempts.first?.success == true)
    }

    @Test("Failed authentication")
    func failedAuthentication() async {
        let repository = MockAuthenticationRepository(shouldFail: true)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "Test authentication", policy: policy)

        guard case .failure = result else {
            #expect(Bool(false), "Authentication should have failed")
            return
        }

        // Verify failed attempt was recorded
        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 1)
        #expect(attempts.first?.success == false)
    }

    @Test("Authentication with empty reason")
    func authenticationWithEmptyReason() async {
        let repository = MockAuthenticationRepository()
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "", policy: policy)

        guard case .failure(let error) = result else {
            #expect(Bool(false), "Authentication should have failed with empty reason")
            return
        }

        if case .invalidRequest(let reason) = error {
            #expect(reason.contains("empty"))
        } else {
            #expect(Bool(false), "Should be invalid request error")
        }

        // Verify failed attempt was recorded
        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 1)
        #expect(attempts.first?.success == false)
    }

    @Test("Authentication with whitespace-only reason")
    func authenticationWithWhitespaceOnlyReason() async {
        let repository = MockAuthenticationRepository()
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "   \n\t   ", policy: policy)

        guard case .failure(let error) = result else {
            #expect(Bool(false), "Authentication should have failed with whitespace-only reason")
            return
        }

        if case .invalidRequest(let reason) = error {
            #expect(reason.contains("empty"))
        } else {
            #expect(Bool(false), "Should be invalid request error")
        }
    }

    @Test("Authentication with too long reason")
    func authenticationWithTooLongReason() async {
        let repository = MockAuthenticationRepository()
        let stateManager = MockAuthenticationStateManager()

        let shortConfig = AuthenticationSecurityConfig(
            maxFailedAttempts: 5,
            rateLimitDuration: 300,
            maxReasonLength: 10
        )

        let useCase = AuthenticationUseCaseImpl(
            repository: repository,
            securityConfig: shortConfig,
            stateManager: stateManager
        )

        let policy = AuthenticationPolicy.standard
        let longReason = String(repeating: "A", count: 20) // 20 characters > 10 limit
        let result = await useCase.authenticate(reason: longReason, policy: policy)

        guard case .failure(let error) = result else {
            #expect(Bool(false), "Authentication should have failed with too long reason")
            return
        }

        if case .invalidRequest(let reason) = error {
            #expect(reason.contains("too long"))
        } else {
            #expect(Bool(false), "Should be invalid request error")
        }
    }

    // MARK: - Rate Limiting Tests

    @Test("Rate limiting after failed attempts")
    func rateLimitingAfterFailedAttempts() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()

        let strictConfig = AuthenticationSecurityConfig(
            maxFailedAttempts: 2,
            rateLimitDuration: 300, // 5 minutes
            maxReasonLength: 500
        )

        let useCase = AuthenticationUseCaseImpl(
            repository: repository,
            securityConfig: strictConfig,
            stateManager: stateManager
        )

        // Add failed attempts to trigger rate limiting
        await stateManager.addFailedAttempts(count: 2)

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "Test after rate limit", policy: policy)

        guard case .failure(let error) = result else {
            #expect(Bool(false), "Authentication should have been rate limited")
            return
        }

        if case .rateLimited = error {
            // Expected
        } else {
            #expect(Bool(false), "Should be rate limited error")
        }
    }

    @Test("No rate limiting with successful attempts")
    func noRateLimitingWithSuccessfulAttempts() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()

        let strictConfig = AuthenticationSecurityConfig(
            maxFailedAttempts: 2,
            rateLimitDuration: 300,
            maxReasonLength: 500
        )

        let useCase = AuthenticationUseCaseImpl(
            repository: repository,
            securityConfig: strictConfig,
            stateManager: stateManager
        )

        // Add successful attempts - should not trigger rate limiting
        for i in 0..<3 {
            await stateManager.recordAttempt(
                AuthenticationAttempt(
                    timestamp: Date(),
                    success: true,
                    method: .touchID,
                    reason: "Successful attempt \(i)"
                )
            )
        }

        let policy = AuthenticationPolicy.standard
        let result = await useCase.authenticate(reason: "Test after successful attempts", policy: policy)

        #expect(result.isSuccess)
    }

    // MARK: - Caching Tests

    @Test("Authentication cache hit")
    func authenticationCacheHit() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Set up recent authentication
        let recentAuth = AuthenticationSuccess(
            authenticatedAt: Date().addingTimeInterval(-30), // 30 seconds ago
            method: .faceID,
            cached: false
        )
        await stateManager.setLastAuthentication(recentAuth)

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: true,
            cacheDuration: 60 // 1 minute
        )

        let result = await useCase.authenticate(reason: "Test cache hit", policy: policy)

        guard case .success(let success) = result else {
            #expect(Bool(false), "Authentication should have succeeded with cache hit")
            return
        }

        #expect(success.cached == true)
        #expect(success.method == .cached)
    }

    @Test("Authentication cache miss - expired")
    func authenticationCacheMissExpired() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Set up old authentication
        let oldAuth = AuthenticationSuccess(
            authenticatedAt: Date().addingTimeInterval(-120), // 2 minutes ago
            method: .faceID,
            cached: false
        )
        await stateManager.setLastAuthentication(oldAuth)

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: true,
            cacheDuration: 60 // 1 minute
        )

        let result = await useCase.authenticate(reason: "Test cache miss", policy: policy)

        guard case .success(let success) = result else {
            #expect(Bool(false), "Authentication should have succeeded")
            return
        }

        #expect(success.cached == false)
        #expect(success.method != .cached)
    }

    @Test("Authentication cache miss - no cached auth")
    func authenticationCacheMissNoCachedAuth() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // No cached authentication

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: true,
            cacheDuration: 60
        )

        let result = await useCase.authenticate(reason: "Test no cache", policy: policy)

        guard case .success(let success) = result else {
            #expect(Bool(false), "Authentication should have succeeded")
            return
        }

        #expect(success.cached == false)
        #expect(success.method != .cached)
    }

    @Test("Authentication ignore cache when policy disallows")
    func authenticationIgnoreCacheWhenPolicyDisallows() async {
        let repository = MockAuthenticationRepository(shouldFail: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Set up recent authentication
        let recentAuth = AuthenticationSuccess(
            authenticatedAt: Date().addingTimeInterval(-30),
            method: .faceID,
            cached: false
        )
        await stateManager.setLastAuthentication(recentAuth)

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: false, // Cache disabled
            cacheDuration: 60
        )

        let result = await useCase.authenticate(reason: "Test ignore cache", policy: policy)

        guard case .success(let success) = result else {
            #expect(Bool(false), "Authentication should have succeeded")
            return
        }

        #expect(success.cached == false)
        #expect(success.method != .cached)
    }

    // MARK: - Biometric Availability Tests

    @Test("Check biometric availability - available")
    func checkBiometricAvailabilityAvailable() async {
        let repository = MockAuthenticationRepository(biometricAvailable: true)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let availability = await useCase.checkBiometricAvailability()

        #expect(availability.isAvailable == true)
        #expect(availability.biometricType == .touchID)
        #expect(availability.unavailableReason == nil)
    }

    @Test("Check biometric availability - unavailable")
    func checkBiometricAvailabilityUnavailable() async {
        let repository = MockAuthenticationRepository(biometricAvailable: false)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let availability = await useCase.checkBiometricAvailability()

        #expect(availability.isAvailable == false)
        #expect(availability.biometricType == nil)
        #expect(availability.unavailableReason != nil)
    }

    // MARK: - Cache Management Tests

    @Test("Clear authentication cache")
    func clearAuthenticationCache() async {
        let repository = MockAuthenticationRepository()
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Set up cached authentication
        let auth = AuthenticationSuccess(
            authenticatedAt: Date(),
            method: .touchID,
            cached: false
        )
        await stateManager.setLastAuthentication(auth)

        // Verify it exists
        let beforeClear = await useCase.getLastAuthentication()
        #expect(beforeClear != nil)

        // Clear cache
        await useCase.clearAuthenticationCache()

        // Verify it's cleared
        let afterClear = await useCase.getLastAuthentication()
        #expect(afterClear == nil)
    }

    @Test("Get last authentication")
    func getLastAuthentication() async {
        let repository = MockAuthenticationRepository()
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Initially nil
        let initial = await useCase.getLastAuthentication()
        #expect(initial == nil)

        // Set authentication
        let auth = AuthenticationSuccess(
            authenticatedAt: Date(),
            method: .faceID,
            cached: false
        )
        await stateManager.setLastAuthentication(auth)

        // Verify retrieval
        let retrieved = await useCase.getLastAuthentication()
        #expect(retrieved != nil)
        #expect(retrieved?.method == .faceID)
    }

    // MARK: - AuthenticationStateUseCaseImpl Tests

    @Test("AuthenticationStateUseCaseImpl initialization")
    func authenticationStateUseCaseImplInitialization() {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()

        let useCase = AuthenticationStateUseCaseImpl(
            stateManager: stateManager,
            repository: repository
        )

        #expect(useCase != nil)
    }

    @Test("isAuthenticated with valid cache")
    func isAuthenticatedWithValidCache() async {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()
        let useCase = AuthenticationStateUseCaseImpl(stateManager: stateManager, repository: repository)

        // Set recent authentication
        let recentAuth = AuthenticationSuccess(
            authenticatedAt: Date().addingTimeInterval(-30), // 30 seconds ago
            method: .touchID,
            cached: false
        )
        await stateManager.setLastAuthentication(recentAuth)

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: true,
            cacheDuration: 60 // 1 minute
        )

        let isAuthenticated = await useCase.isAuthenticated(policy: policy)
        #expect(isAuthenticated == true)
    }

    @Test("isAuthenticated with expired cache")
    func isAuthenticatedWithExpiredCache() async {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()
        let useCase = AuthenticationStateUseCaseImpl(stateManager: stateManager, repository: repository)

        // Set old authentication
        let oldAuth = AuthenticationSuccess(
            authenticatedAt: Date().addingTimeInterval(-120), // 2 minutes ago
            method: .touchID,
            cached: false
        )
        await stateManager.setLastAuthentication(oldAuth)

        let policy = AuthenticationPolicy(
            requireRecentAuthentication: true,
            cacheDuration: 60 // 1 minute
        )

        let isAuthenticated = await useCase.isAuthenticated(policy: policy)
        #expect(isAuthenticated == false)
    }

    @Test("isAuthenticated with no cache")
    func isAuthenticatedWithNoCache() async {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()
        let useCase = AuthenticationStateUseCaseImpl(stateManager: stateManager, repository: repository)

        // No cached authentication

        let policy = AuthenticationPolicy.standard
        let isAuthenticated = await useCase.isAuthenticated(policy: policy)
        #expect(isAuthenticated == false)
    }

    @Test("Invalidate authentication")
    func invalidateAuthentication() async {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()
        let useCase = AuthenticationStateUseCaseImpl(stateManager: stateManager, repository: repository)

        // Set authentication
        let auth = AuthenticationSuccess(
            authenticatedAt: Date(),
            method: .touchID,
            cached: false
        )
        await stateManager.setLastAuthentication(auth)

        // Verify it exists
        let beforeInvalidate = await stateManager.getLastAuthentication()
        #expect(beforeInvalidate != nil)

        // Invalidate
        await useCase.invalidateAuthentication()

        // Verify it's cleared
        let afterInvalidate = await stateManager.getLastAuthentication()
        #expect(afterInvalidate == nil)
    }

    @Test("Get authentication history")
    func getAuthenticationHistory() async {
        let stateManager = MockAuthenticationStateManager()
        let repository = MockAuthenticationRepository()
        let useCase = AuthenticationStateUseCaseImpl(stateManager: stateManager, repository: repository)

        // Add some attempts
        await stateManager.recordAttempt(
            AuthenticationAttempt(timestamp: Date(), success: true, method: .touchID, reason: "Test 1")
        )
        await stateManager.recordAttempt(
            AuthenticationAttempt(timestamp: Date(), success: false, method: nil, reason: "Test 2")
        )

        let history = await useCase.getAuthenticationHistory()
        #expect(history.count == 2)
        #expect(history[0].success == true)
        #expect(history[1].success == false)
    }

    // MARK: - InMemoryAuthenticationStateManager Tests

    @Test("InMemoryAuthenticationStateManager initialization")
    func inMemoryAuthenticationStateManagerInitialization() {
        let stateManager = InMemoryAuthenticationStateManager()
        #expect(stateManager != nil)
    }

    @Test("Record and retrieve authentication attempts")
    func recordAndRetrieveAuthenticationAttempts() async {
        let stateManager = InMemoryAuthenticationStateManager()

        let attempt1 = AuthenticationAttempt(
            timestamp: Date(),
            success: true,
            method: .touchID,
            reason: "First attempt"
        )

        let attempt2 = AuthenticationAttempt(
            timestamp: Date().addingTimeInterval(10),
            success: false,
            method: nil,
            reason: "Second attempt"
        )

        await stateManager.recordAttempt(attempt1)
        await stateManager.recordAttempt(attempt2)

        let allAttempts = await stateManager.getAllAttempts()
        #expect(allAttempts.count == 2)
        #expect(allAttempts[0].reason == "First attempt")
        #expect(allAttempts[1].reason == "Second attempt")
    }

    @Test("Get recent attempts since date")
    func getRecentAttemptsSinceDate() async {
        let stateManager = InMemoryAuthenticationStateManager()

        let oldDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let recentDate = Date().addingTimeInterval(-600) // 10 minutes ago

        let oldAttempt = AuthenticationAttempt(
            timestamp: oldDate,
            success: true,
            method: .touchID,
            reason: "Old attempt"
        )

        let recentAttempt = AuthenticationAttempt(
            timestamp: recentDate,
            success: false,
            method: nil,
            reason: "Recent attempt"
        )

        await stateManager.recordAttempt(oldAttempt)
        await stateManager.recordAttempt(recentAttempt)

        let since30MinutesAgo = Date().addingTimeInterval(-1800)
        let recentAttempts = await stateManager.getRecentAttempts(since: since30MinutesAgo)

        #expect(recentAttempts.count == 1)
        #expect(recentAttempts[0].reason == "Recent attempt")
    }

    @Test("History size limitation")
    func historySizeLimitation() async {
        let stateManager = InMemoryAuthenticationStateManager()

        // Add more than maxHistorySize (100) attempts
        for i in 0..<150 {
            let attempt = AuthenticationAttempt(
                timestamp: Date().addingTimeInterval(TimeInterval(i)),
                success: i % 2 == 0,
                method: .touchID,
                reason: "Attempt \(i)"
            )
            await stateManager.recordAttempt(attempt)
        }

        let allAttempts = await stateManager.getAllAttempts()
        #expect(allAttempts.count == 100) // Should be limited to maxHistorySize
        #expect(allAttempts.first?.reason == "Attempt 50") // First 50 should be removed
        #expect(allAttempts.last?.reason == "Attempt 149")
    }

    @Test("Last authentication management")
    func lastAuthenticationManagement() async {
        let stateManager = InMemoryAuthenticationStateManager()

        // Initially nil
        let initial = await stateManager.getLastAuthentication()
        #expect(initial == nil)

        // Set authentication
        let auth1 = AuthenticationSuccess(
            authenticatedAt: Date(),
            method: .touchID,
            cached: false
        )
        await stateManager.updateLastAuthentication(auth1)

        let retrieved1 = await stateManager.getLastAuthentication()
        #expect(retrieved1?.method == .touchID)

        // Update authentication
        let auth2 = AuthenticationSuccess(
            authenticatedAt: Date(),
            method: .faceID,
            cached: true
        )
        await stateManager.updateLastAuthentication(auth2)

        let retrieved2 = await stateManager.getLastAuthentication()
        #expect(retrieved2?.method == .faceID)
        #expect(retrieved2?.cached == true)

        // Clear cache
        await stateManager.clearCache()

        let afterClear = await stateManager.getLastAuthentication()
        #expect(afterClear == nil)
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("Authentication method extraction from success result")
    func authenticationMethodExtractionFromSuccessResult() async {
        let repository = MockAuthenticationRepository(
            shouldFail: false,
            authenticationMethod: .faceID
        )
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let result = await useCase.authenticate(reason: "Test method extraction", policy: .standard)

        #expect(result.isSuccess)

        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 1)
        #expect(attempts.first?.method == .faceID)
    }

    @Test("Authentication method extraction from failure result")
    func authenticationMethodExtractionFromFailureResult() async {
        let repository = MockAuthenticationRepository(shouldFail: true)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        let result = await useCase.authenticate(reason: "Test method extraction failure", policy: .standard)

        #expect(!result.isSuccess)

        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 1)
        #expect(attempts.first?.method == nil) // Should be nil for failed attempts
    }

    @Test("Concurrent authentication attempts")
    func concurrentAuthenticationAttempts() async {
        let repository = MockAuthenticationRepository(simulateDelay: true)
        let stateManager = MockAuthenticationStateManager()
        let useCase = AuthenticationUseCaseImpl(repository: repository, stateManager: stateManager)

        // Start multiple concurrent authentications
        async let result1 = useCase.authenticate(reason: "Concurrent test 1", policy: .standard)
        async let result2 = useCase.authenticate(reason: "Concurrent test 2", policy: .standard)
        async let result3 = useCase.authenticate(reason: "Concurrent test 3", policy: .standard)

        let results = await [result1, result2, result3]

        // All should succeed
        #expect(results.allSatisfy { $0.isSuccess })

        // All attempts should be recorded
        let attempts = await stateManager.getAllAttempts()
        #expect(attempts.count == 3)
    }
}
