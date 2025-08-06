//
//  ProtectedActionUseCaseTests.swift
//  MagSafeGuardDomainTests
//
//  Created on 2025-08-06.
//
//  Unit tests for ProtectedActionUseCase using Swift Testing framework.
//

import Foundation
import Testing
@testable import MagSafeGuardDomain
@testable import TestInfrastructure

@Suite("Protected Action Use Case")
struct ProtectedActionUseCaseTests {
    
    // MARK: - Lock Screen Tests
    
    @Test("Lock screen executes successfully with protection validation")
    func lockScreenSuccessFlow() async {
        // Given
        let context = TestContext()
        context.mockRepository.lockScreenShouldSucceed = true
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .lockScreen) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockProtectionPolicy.validateActionCalled)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .lockScreen)
        #expect(context.mockRepository.lockScreenCalled)
        #expect(context.mockProtectionPolicy.recordSuccessCalled)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .lockScreen)
        
        if case .failure = result {
            Issue.record("Expected success but got failure")
        }
    }
    
    @Test("Lock screen denied by protection policy triggers failure flow")
    func lockScreenProtectionDenied() async {
        // Given
        let context = TestContext()
        context.mockProtectionPolicy.shouldFailValidation = true
        context.mockProtectionPolicy.validationError = .rateLimitExceeded
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .lockScreen) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockProtectionPolicy.validateActionCalled)
        #expect(!context.mockRepository.lockScreenCalled, "Should not execute if protection denies")
        #expect(context.mockProtectionPolicy.recordFailureCalled)
        #expect(context.mockProtectionPolicy.lastFailureAction == .lockScreen)
        
        if case .failure(let error) = result {
            #expect(error == .rateLimitExceeded)
        } else {
            Issue.record("Expected failure but got success")
        }
    }
    
    @Test("Repository failure triggers protection failure recording")
    func lockScreenRepositoryFailure() async {
        // Given
        let context = TestContext()
        context.mockRepository.lockScreenShouldSucceed = false
        context.mockRepository.lockScreenError = SecurityActionError.actionFailed(type: .lockScreen, reason: "Test failure")
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .lockScreen) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockProtectionPolicy.validateActionCalled)
        #expect(context.mockRepository.lockScreenCalled)
        #expect(context.mockProtectionPolicy.recordFailureCalled)
        #expect(context.mockProtectionPolicy.lastFailureAction == .lockScreen)
        
        if case .failure(let error) = result,
           case .actionFailed(let type, _) = error {
            #expect(type == .lockScreen)
        } else {
            Issue.record("Expected actionFailed error")
        }
    }
    
    // MARK: - Alarm Tests
    
    @Test("Play alarm with volume validates and executes correctly", 
          arguments: [0.0, 0.5, 0.8, 1.0])
    func playAlarmWithVolume(volume: Float) async {
        // Given
        let context = TestContext()
        context.mockRepository.playAlarmShouldSucceed = true
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .playAlarm(volume: volume)) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockRepository.playAlarmCalled)
        #expect(context.mockRepository.lastAlarmVolume == volume)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .soundAlarm)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .soundAlarm)
    }
    
    @Test("Stop alarm executes without errors")
    func stopAlarm() async {
        // Given
        let context = TestContext()
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .stopAlarm) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockRepository.stopAlarmCalled)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .soundAlarm)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .soundAlarm)
    }
    
    // MARK: - Logout Tests
    
    @Test("Force logout executes with proper validation")
    func forceLogout() async {
        // Given
        let context = TestContext()
        context.mockRepository.forceLogoutShouldSucceed = true
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .forceLogout) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockRepository.forceLogoutCalled)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .forceLogout)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .forceLogout)
    }
    
    // MARK: - Shutdown Tests
    
    @Test("Schedule shutdown with delay parameter", 
          arguments: [0.0, 30.0, 60.0, 300.0])
    func scheduleShutdown(delay: TimeInterval) async {
        // Given
        let context = TestContext()
        context.mockRepository.scheduleShutdownShouldSucceed = true
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .scheduleShutdown(afterSeconds: delay)) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockRepository.scheduleShutdownCalled)
        #expect(context.mockRepository.lastShutdownDelay == delay)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .shutdown)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .shutdown)
    }
    
    // MARK: - Script Execution Tests
    
    @Test("Execute script with path validation", 
          arguments: [
              "/usr/local/bin/test.sh",
              "/home/user/scripts/security.bash",
              "/opt/custom/action.zsh"
          ])
    func executeScript(scriptPath: String) async {
        // Given
        let context = TestContext()
        context.mockRepository.executeScriptShouldSucceed = true
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .executeScript(path: scriptPath)) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockRepository.executeScriptCalled)
        #expect(context.mockRepository.lastScriptPath == scriptPath)
        #expect(context.mockProtectionPolicy.lastValidatedAction == .customScript)
        #expect(context.mockProtectionPolicy.lastSuccessAction == .customScript)
    }
    
    // MARK: - Metrics Tests
    
    @Test("Get metrics returns policy metrics")
    func getMetrics() async {
        // Given
        let context = TestContext()
        let expectedMetrics = ProtectionMetricsBuilder()
            .withTotalAttempts(10)
            .withSuccessfulExecutions(8)
            .withRateLimitedAttempts(2)
            .build()
        context.mockProtectionPolicy.mockMetrics = expectedMetrics
        
        // When
        let metrics = await context.sut.getMetrics(for: .lockScreen)
        
        // Then
        #expect(metrics.totalAttempts == 10)
        #expect(metrics.successfulExecutions == 8)
        #expect(metrics.rateLimitedAttempts == 2)
    }
    
    @Test("Reset protection delegates to policy")
    func resetProtection() async {
        // Given
        let context = TestContext()
        
        // When
        await context.sut.resetProtection(for: .lockScreen)
        
        // Then
        #expect(context.mockProtectionPolicy.resetCalled)
        #expect(context.mockProtectionPolicy.lastResetAction == .lockScreen)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Unexpected errors are converted to system errors")
    func unexpectedErrorHandling() async {
        // Given
        struct CustomError: Error {}
        let context = TestContext()
        context.mockRepository.shouldThrowCustomError = true
        context.mockRepository.customError = CustomError()
        var result: Result<Void, SecurityActionError>?
        
        // When
        await context.sut.execute(action: .lockScreen) { completionResult in
            result = completionResult
        }
        
        // Then
        #expect(result != nil)
        #expect(context.mockProtectionPolicy.recordFailureCalled)
        
        if case .failure(let error) = result,
           case .systemError = error {
            // Expected error type
        } else {
            Issue.record("Expected systemError but got different error type")
        }
    }
    
    // MARK: - Action Type Mapping Tests
    
    @Test("Action types map correctly to SecurityActionType")
    func actionTypeMapping() {
        #expect(ProtectedSecurityAction.lockScreen.actionType == .lockScreen)
        #expect(ProtectedSecurityAction.playAlarm(volume: 0.5).actionType == .soundAlarm)
        #expect(ProtectedSecurityAction.stopAlarm.actionType == .soundAlarm)
        #expect(ProtectedSecurityAction.forceLogout.actionType == .forceLogout)
        #expect(ProtectedSecurityAction.scheduleShutdown(afterSeconds: 60).actionType == .shutdown)
        #expect(ProtectedSecurityAction.executeScript(path: "/test").actionType == .customScript)
    }
    
    // MARK: - Factory Tests
    
    @Test("Use case factory creates correct instance")
    func useCaseFactory() {
        // Given
        let context = TestContext()
        
        // When
        let useCase = ProtectedActionUseCaseFactory.make(
            repository: context.mockRepository,
            protectionPolicy: context.mockProtectionPolicy
        )
        
        // Then
        #expect(useCase is ProtectedActionUseCase)
    }
}

// MARK: - Test Helpers

private extension ProtectedActionUseCaseTests {
    struct TestContext {
        let sut: ProtectedActionUseCase
        let mockRepository: MockSecurityActionRepository
        let mockProtectionPolicy: MockResourceProtectionPolicy
        
        init() {
            mockRepository = MockSecurityActionRepository()
            mockProtectionPolicy = MockResourceProtectionPolicy()
            sut = ProtectedActionUseCase(
                repository: mockRepository,
                protectionPolicy: mockProtectionPolicy
            )
        }
    }
}