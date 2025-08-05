//
//  DomainProtocolTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Tests for Domain layer protocols and models to ensure proper business logic coverage
//

import Foundation
@testable import MagSafeGuardDomain
import Testing

// MARK: - Mock Repository for Testing

/// Mock SecurityActionRepository for testing execution strategies
private final class MockSecurityActionRepository: SecurityActionRepository, @unchecked Sendable {
    private let shouldFail: Bool
    private let shouldFailShutdown: Bool

    init(shouldFail: Bool = false, shouldFailShutdown: Bool = false) {
        self.shouldFail = shouldFail
        self.shouldFailShutdown = shouldFailShutdown
    }

    func lockScreen() async throws {
        if shouldFail {
            throw SecurityActionError.actionFailed(type: .lockScreen, reason: "Mock failure")
        }
    }

    func playAlarm(volume: Float) async throws {
        if shouldFail {
            throw SecurityActionError.actionFailed(type: .soundAlarm, reason: "Mock failure")
        }
    }

    func stopAlarm() async {
        // No-op for testing
    }

    func forceLogout() async throws {
        if shouldFail {
            throw SecurityActionError.actionFailed(type: .forceLogout, reason: "Mock failure")
        }
    }

    func scheduleShutdown(afterSeconds: TimeInterval) async throws {
        if shouldFail || shouldFailShutdown {
            throw SecurityActionError.actionFailed(type: .shutdown, reason: "Mock shutdown failure")
        }
    }

    func executeScript(at path: String) async throws {
        if shouldFail {
            throw SecurityActionError.scriptNotFound(path: path)
        }
    }
}

@Suite("Domain Protocol Tests")
struct DomainProtocolTests {

    // MARK: - SecurityActionType Tests

    @Test("SecurityActionType has all expected cases")
    func securityActionTypeAllCases() {
        let expectedCases: Set<SecurityActionType> = [
            .lockScreen,
            .soundAlarm,
            .forceLogout,
            .shutdown,
            .customScript
        ]

        let actualCases = Set(SecurityActionType.allCases)
        #expect(actualCases == expectedCases)
        #expect(SecurityActionType.allCases.count == 5)
    }

    @Test("SecurityActionType display names are correct")
    func securityActionTypeDisplayNames() {
        #expect(SecurityActionType.lockScreen.displayName == "Lock Screen")
        #expect(SecurityActionType.soundAlarm.displayName == "Sound Alarm")
        #expect(SecurityActionType.forceLogout.displayName == "Force Logout")
        #expect(SecurityActionType.shutdown.displayName == "System Shutdown")
        #expect(SecurityActionType.customScript.displayName == "Custom Script")
    }

    @Test("SecurityActionType symbol names are valid SF Symbols")
    func securityActionTypeSymbolNames() {
        #expect(SecurityActionType.lockScreen.symbolName == "lock.fill")
        #expect(SecurityActionType.soundAlarm.symbolName == "speaker.wave.3.fill")
        #expect(SecurityActionType.forceLogout.symbolName == "arrow.right.square.fill")
        #expect(SecurityActionType.shutdown.symbolName == "power")
        #expect(SecurityActionType.customScript.symbolName == "terminal.fill")
    }

    @Test("SecurityActionType descriptions contain key terms")
    func securityActionTypeDescriptions() {
        #expect(SecurityActionType.lockScreen.description.localizedCaseInsensitiveContains("lock"))
        #expect(SecurityActionType.soundAlarm.description.localizedCaseInsensitiveContains("alarm"))
        #expect(SecurityActionType.forceLogout.description.localizedCaseInsensitiveContains("logout"))
        #expect(SecurityActionType.shutdown.description.localizedCaseInsensitiveContains("shutdown"))
        #expect(SecurityActionType.customScript.description.localizedCaseInsensitiveContains("script"))
    }

    @Test("SecurityActionType is Codable")
    func securityActionTypeCodable() throws {
        let actions: [SecurityActionType] = [.lockScreen, .soundAlarm, .customScript]

        let encoder = JSONEncoder()
        let data = try encoder.encode(actions)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([SecurityActionType].self, from: data)

        #expect(decoded == actions)
    }

    @Test("SecurityActionType raw values are stable")
    func securityActionTypeRawValues() {
        // Ensure raw values don't change (important for persistence)
        #expect(SecurityActionType.lockScreen.rawValue == "lock_screen")
        #expect(SecurityActionType.soundAlarm.rawValue == "sound_alarm")
        #expect(SecurityActionType.forceLogout.rawValue == "force_logout")
        #expect(SecurityActionType.shutdown.rawValue == "shutdown")
        #expect(SecurityActionType.customScript.rawValue == "custom_script")
    }

    // MARK: - PowerStateInfo Tests

    @Test("PowerStateInfo initializes correctly")
    func powerStateInfoInitialization() {
        let timestamp = Date()
        let powerState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp
        )

        #expect(powerState.isConnected == true)
        #expect(powerState.batteryLevel == 85)
        #expect(powerState.isCharging == true)
        #expect(powerState.adapterWattage == 96)
        #expect(powerState.timestamp == timestamp)
    }

    @Test("PowerStateInfo handles optional values")
    func powerStateInfoOptionalValues() {
        let timestamp = Date()
        let powerState = PowerStateInfo(
            isConnected: false,
            batteryLevel: nil,
            isCharging: false,
            adapterWattage: nil,
            timestamp: timestamp
        )

        #expect(powerState.isConnected == false)
        #expect(powerState.batteryLevel == nil)
        #expect(powerState.isCharging == false)
        #expect(powerState.adapterWattage == nil)
        #expect(powerState.timestamp == timestamp)
    }

    @Test("PowerStateInfo is Equatable")
    func powerStateInfoEquatable() {
        let timestamp = Date()
        let powerState1 = PowerStateInfo(
            isConnected: true,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp
        )

        let powerState2 = PowerStateInfo(
            isConnected: true,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp
        )

        let powerState3 = PowerStateInfo(
            isConnected: false,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp
        )

        #expect(powerState1 == powerState2)
        #expect(powerState1 != powerState3)
    }

    @Test("PowerStateInfo timestamp comparison")
    func powerStateInfoTimestampComparison() {
        let timestamp1 = Date()
        let timestamp2 = Date().addingTimeInterval(60) // 1 minute later

        let powerState1 = PowerStateInfo(
            isConnected: true,
            batteryLevel: 85,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp1
        )

        let powerState2 = PowerStateInfo(
            isConnected: true,
            batteryLevel: 90,
            isCharging: true,
            adapterWattage: 96,
            timestamp: timestamp2
        )

        // Test timestamp ordering (manual comparison)
        #expect(powerState1.timestamp < powerState2.timestamp)
        #expect(!(powerState2.timestamp < powerState1.timestamp))
    }

    // MARK: - SecurityAnalysis SecurityAction Tests

    @Test("SecurityAction cases are available")
    func securityActionCases() {
        // Test that all SecurityAction cases from SecurityAnalysis work
        let actions: [SecurityAnalysis.SecurityAction] = [
            .none,
            .notify,
            .lockScreen,
            .shutdown,
            .custom("test action")
        ]

        #expect(actions.count == 5)
        #expect(actions.contains(.none))
        #expect(actions.contains(.lockScreen))
        #expect(actions.contains(.shutdown))
    }

    @Test("SecurityAction is Equatable")
    func securityActionEquatable() {
        let action1: SecurityAnalysis.SecurityAction = .lockScreen
        let action2: SecurityAnalysis.SecurityAction = .lockScreen
        let action3: SecurityAnalysis.SecurityAction = .shutdown
        let custom1: SecurityAnalysis.SecurityAction = .custom("test")
        let custom2: SecurityAnalysis.SecurityAction = .custom("test")
        let custom3: SecurityAnalysis.SecurityAction = .custom("different")

        #expect(action1 == action2)
        #expect(action1 != action3)
        #expect(custom1 == custom2)
        #expect(custom1 != custom3)
    }

    // MARK: - SecurityActionConfiguration Tests

    @Test("SecurityActionConfiguration has default values")
    func securityActionConfigurationDefaults() {
        let config = SecurityActionConfiguration.defaultConfig

        #expect(config.enabledActions.contains(.lockScreen))
        #expect(config.actionDelay >= 0)
        #expect(config.alarmVolume >= 0.0)
        #expect(config.alarmVolume <= 1.0)
        #expect(config.shutdownDelay >= 0)
    }

    @Test("SecurityActionConfiguration initialization")
    func securityActionConfigurationInit() {
        let enabledActions: Set<SecurityActionType> = [.lockScreen, .soundAlarm]
        let config = SecurityActionConfiguration(
            enabledActions: enabledActions,
            actionDelay: 5.0,
            alarmVolume: 0.8,
            shutdownDelay: 30.0,
            customScriptPath: "/usr/bin/test.sh",
            executeInParallel: true
        )

        #expect(config.enabledActions == enabledActions)
        #expect(config.actionDelay == 5.0)
        #expect(config.alarmVolume == 0.8)
        #expect(config.shutdownDelay == 30.0)
        #expect(config.customScriptPath == "/usr/bin/test.sh")
        #expect(config.executeInParallel == true)
    }

    @Test("SecurityActionConfiguration volume clamping")
    func securityActionConfigurationVolumeClamping() {
        // Test volume gets clamped to 0-1 range
        let config1 = SecurityActionConfiguration(alarmVolume: -0.5)
        #expect(config1.alarmVolume == 0.0)

        let config2 = SecurityActionConfiguration(alarmVolume: 1.5)
        #expect(config2.alarmVolume == 1.0)

        let config3 = SecurityActionConfiguration(alarmVolume: 0.5)
        #expect(config3.alarmVolume == 0.5)
    }

    @Test("SecurityActionConfiguration shutdown delay validation")
    func securityActionConfigurationShutdownDelay() {
        // Test shutdown delay gets clamped to minimum 0
        let config1 = SecurityActionConfiguration(shutdownDelay: -10)
        #expect(config1.shutdownDelay == 0)

        let config2 = SecurityActionConfiguration(shutdownDelay: 60)
        #expect(config2.shutdownDelay == 60)
    }

    // MARK: - SecurityTrigger Tests

    @Test("SecurityTrigger descriptions")
    func securityTriggerDescriptions() {
        #expect(SecurityTrigger.powerDisconnected.description == "Power adapter disconnected")
        #expect(SecurityTrigger.manualTrigger.description == "Manually triggered by user")
        #expect(SecurityTrigger.testTrigger.description == "Test trigger")

        let customTrigger = SecurityTrigger.customTrigger("Custom security event")
        #expect(customTrigger.description == "Custom security event")
    }

    @Test("SecurityTrigger is Equatable")
    func securityTriggerEquatable() {
        let trigger1 = SecurityTrigger.powerDisconnected
        let trigger2 = SecurityTrigger.powerDisconnected
        let trigger3 = SecurityTrigger.manualTrigger

        #expect(trigger1 == trigger2)
        #expect(trigger1 != trigger3)

        let custom1 = SecurityTrigger.customTrigger("test")
        let custom2 = SecurityTrigger.customTrigger("test")
        let custom3 = SecurityTrigger.customTrigger("different")

        #expect(custom1 == custom2)
        #expect(custom1 != custom3)
    }

    // MARK: - SecurityActionRequest Tests

    @Test("SecurityActionRequest initialization")
    func securityActionRequestInit() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.powerDisconnected
        let timestamp = Date()

        let request = SecurityActionRequest(
            configuration: config,
            trigger: trigger,
            timestamp: timestamp
        )

        #expect(request.configuration == config)
        #expect(request.trigger == trigger)
        #expect(request.timestamp == timestamp)
    }

    @Test("SecurityActionRequest default timestamp")
    func securityActionRequestDefaultTimestamp() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.manualTrigger

        let request = SecurityActionRequest(
            configuration: config,
            trigger: trigger
        )

        #expect(request.configuration == config)
        #expect(request.trigger == trigger)
        #expect(abs(request.timestamp.timeIntervalSinceNow) < 1)
    }

    // MARK: - SecurityActionExecutionResult Tests

    @Test("SecurityActionExecutionResult initialization")
    func securityActionExecutionResultInit() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.testTrigger
        let request = SecurityActionRequest(configuration: config, trigger: trigger)

        let result1 = SecurityActionResult(actionType: .lockScreen, success: true)
        let result2 = SecurityActionResult(actionType: .soundAlarm, success: false, error: .actionFailed(type: .soundAlarm, reason: "Volume error"))
        let executedActions = [result1, result2]

        let startTime = Date()
        let endTime = Date().addingTimeInterval(5)

        let executionResult = SecurityActionExecutionResult(
            request: request,
            executedActions: executedActions,
            startTime: startTime,
            endTime: endTime
        )

        #expect(executionResult.request == request)
        #expect(executionResult.executedActions == executedActions)
        #expect(executionResult.startTime == startTime)
        #expect(executionResult.endTime == endTime)
    }

    @Test("SecurityActionExecutionResult allSucceeded computation")
    func securityActionExecutionResultAllSucceeded() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.testTrigger
        let request = SecurityActionRequest(configuration: config, trigger: trigger)

        // All successful
        let successfulActions = [
            SecurityActionResult(actionType: .lockScreen, success: true),
            SecurityActionResult(actionType: .soundAlarm, success: true)
        ]
        let allSuccessResult = SecurityActionExecutionResult(
            request: request,
            executedActions: successfulActions,
            startTime: Date(),
            endTime: Date()
        )
        #expect(allSuccessResult.allSucceeded == true)

        // Some failed
        let mixedActions = [
            SecurityActionResult(actionType: .lockScreen, success: true),
            SecurityActionResult(actionType: .soundAlarm, success: false)
        ]
        let mixedResult = SecurityActionExecutionResult(
            request: request,
            executedActions: mixedActions,
            startTime: Date(),
            endTime: Date()
        )
        #expect(mixedResult.allSucceeded == false)
    }

    @Test("SecurityActionExecutionResult failedActions computation")
    func securityActionExecutionResultFailedActions() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.testTrigger
        let request = SecurityActionRequest(configuration: config, trigger: trigger)

        let successResult = SecurityActionResult(actionType: .lockScreen, success: true)
        let failResult = SecurityActionResult(actionType: .soundAlarm, success: false)
        let actions = [successResult, failResult]

        let executionResult = SecurityActionExecutionResult(
            request: request,
            executedActions: actions,
            startTime: Date(),
            endTime: Date()
        )

        let failedActions = executionResult.failedActions
        #expect(failedActions.count == 1)
        #expect(failedActions.first?.actionType == .soundAlarm)
        #expect(failedActions.first?.success == false)
    }

    @Test("SecurityActionExecutionResult duration computation")
    func securityActionExecutionResultDuration() {
        let config = SecurityActionConfiguration.defaultConfig
        let trigger = SecurityTrigger.testTrigger
        let request = SecurityActionRequest(configuration: config, trigger: trigger)

        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3.5)

        let executionResult = SecurityActionExecutionResult(
            request: request,
            executedActions: [],
            startTime: startTime,
            endTime: endTime
        )

        #expect(abs(executionResult.duration - 3.5) < 0.1)
    }

    // MARK: - SecurityActionResult Tests

    @Test("SecurityActionResult initialization")
    func securityActionResultInit() {
        let timestamp = Date()
        let error = SecurityActionError.permissionDenied(action: .shutdown)

        let result = SecurityActionResult(
            actionType: .shutdown,
            success: false,
            error: error,
            executedAt: timestamp
        )

        #expect(result.actionType == .shutdown)
        #expect(result.success == false)
        #expect(result.error == error)
        #expect(result.executedAt == timestamp)
    }

    @Test("SecurityActionResult default values")
    func securityActionResultDefaults() {
        let result = SecurityActionResult(
            actionType: .lockScreen,
            success: true
        )

        #expect(result.actionType == .lockScreen)
        #expect(result.success == true)
        #expect(result.error == nil)
        #expect(abs(result.executedAt.timeIntervalSinceNow) < 1)
    }

    // MARK: - SecurityActionError Tests

    @Test("SecurityActionError errorDescription")
    func securityActionErrorDescriptions() {
        let actionFailedError = SecurityActionError.actionFailed(type: .lockScreen, reason: "Screen lock failed")
        #expect(actionFailedError.errorDescription == "Lock Screen failed: Screen lock failed")

        let alreadyExecutingError = SecurityActionError.alreadyExecuting
        #expect(alreadyExecutingError.errorDescription == "Security actions are already being executed")

        let scriptNotFoundError = SecurityActionError.scriptNotFound(path: "/usr/bin/missing.sh")
        #expect(scriptNotFoundError.errorDescription == "Script not found at path: /usr/bin/missing.sh")

        let permissionDeniedError = SecurityActionError.permissionDenied(action: .shutdown)
        #expect(permissionDeniedError.errorDescription == "Permission denied for action: System Shutdown")

        let systemError = SecurityActionError.systemError(description: "Disk full")
        #expect(systemError.errorDescription == "System error: Disk full")

        let invalidConfigError = SecurityActionError.invalidConfiguration(reason: "No actions enabled")
        #expect(invalidConfigError.errorDescription == "Invalid configuration: No actions enabled")
    }

    @Test("SecurityActionError is Equatable")
    func securityActionErrorEquatable() {
        let error1 = SecurityActionError.actionFailed(type: .lockScreen, reason: "test")
        let error2 = SecurityActionError.actionFailed(type: .lockScreen, reason: "test")
        let error3 = SecurityActionError.actionFailed(type: .lockScreen, reason: "different")

        #expect(error1 == error2)
        #expect(error1 != error3)

        let alreadyExecuting1 = SecurityActionError.alreadyExecuting
        let alreadyExecuting2 = SecurityActionError.alreadyExecuting
        #expect(alreadyExecuting1 == alreadyExecuting2)

        let script1 = SecurityActionError.scriptNotFound(path: "/test")
        let script2 = SecurityActionError.scriptNotFound(path: "/test")
        let script3 = SecurityActionError.scriptNotFound(path: "/different")

        #expect(script1 == script2)
        #expect(script1 != script3)
    }

    // MARK: - SequentialExecutionStrategy Tests

    @Test("SequentialExecutionStrategy initialization")
    func sequentialExecutionStrategyInit() {
        _ = SequentialExecutionStrategy()
        // Just test that it initializes without error
    }

    @Test("SequentialExecutionStrategy executes actions sequentially")
    func sequentialExecutionStrategyExecuteActions() async {
        let strategy = SequentialExecutionStrategy()
        let config = SecurityActionConfiguration(enabledActions: [.lockScreen, .soundAlarm])
        let repository = MockSecurityActionRepository()

        let results = await strategy.executeActions(
            [.lockScreen, .soundAlarm],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 2)
        #expect(results[0].actionType == .lockScreen)
        #expect(results[0].success == true)
        #expect(results[1].actionType == .soundAlarm)
        #expect(results[1].success == true)
    }

    @Test("SequentialExecutionStrategy handles action failures")
    func sequentialExecutionStrategyHandlesFailures() async {
        let strategy = SequentialExecutionStrategy()
        let config = SecurityActionConfiguration(enabledActions: [.shutdown])
        let repository = MockSecurityActionRepository(shouldFail: true)

        let results = await strategy.executeActions(
            [.shutdown],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 1)
        #expect(results[0].actionType == .shutdown)
        #expect(results[0].success == false)
        #expect(results[0].error != nil)
    }

    @Test("SequentialExecutionStrategy handles custom script without path")
    func sequentialExecutionStrategyCustomScriptNoPath() async {
        let strategy = SequentialExecutionStrategy()
        let config = SecurityActionConfiguration(enabledActions: [.customScript])
        let repository = MockSecurityActionRepository()

        let results = await strategy.executeActions(
            [.customScript],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 1)
        #expect(results[0].actionType == .customScript)
        #expect(results[0].success == false)
        #expect(results[0].error != nil)
    }

    @Test("SequentialExecutionStrategy handles custom script with path")
    func sequentialExecutionStrategyCustomScriptWithPath() async {
        let strategy = SequentialExecutionStrategy()
        let config = SecurityActionConfiguration(
            enabledActions: [.customScript],
            customScriptPath: "/usr/bin/test.sh"
        )
        let repository = MockSecurityActionRepository()

        let results = await strategy.executeActions(
            [.customScript],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 1)
        #expect(results[0].actionType == .customScript)
        #expect(results[0].success == true)
    }

    // MARK: - ParallelExecutionStrategy Tests

    @Test("ParallelExecutionStrategy initialization")
    func parallelExecutionStrategyInit() {
        _ = ParallelExecutionStrategy()
        // Just test that it initializes without error
    }

    @Test("ParallelExecutionStrategy executes actions in parallel")
    func parallelExecutionStrategyExecuteActions() async {
        let strategy = ParallelExecutionStrategy()
        let config = SecurityActionConfiguration(enabledActions: [.lockScreen, .soundAlarm])
        let repository = MockSecurityActionRepository()

        let results = await strategy.executeActions(
            [.lockScreen, .soundAlarm],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 2)
        // Results may be in any order due to parallel execution
        let actionTypes = results.map { $0.actionType }
        #expect(actionTypes.contains(.lockScreen))
        #expect(actionTypes.contains(.soundAlarm))
        #expect(results.allSatisfy { $0.success })
    }

    @Test("ParallelExecutionStrategy handles mixed success and failure")
    func parallelExecutionStrategyMixedResults() async {
        let strategy = ParallelExecutionStrategy()
        let config = SecurityActionConfiguration(
            enabledActions: [.lockScreen, .shutdown],
            customScriptPath: "/usr/bin/test.sh"
        )
        let repository = MockSecurityActionRepository(shouldFailShutdown: true)

        let results = await strategy.executeActions(
            [.lockScreen, .shutdown],
            configuration: config,
            repository: repository
        )

        #expect(results.count == 2)
        let lockScreenResult = results.first { $0.actionType == .lockScreen }
        let shutdownResult = results.first { $0.actionType == .shutdown }

        #expect(lockScreenResult?.success == true)
        #expect(shutdownResult?.success == false)
        #expect(shutdownResult?.error != nil)
    }

    // MARK: - Authentication Domain Model Tests

    @Test("AuthenticationRequest initializes correctly")
    func authenticationRequestInitialization() {
        let timestamp = Date()
        let request = AuthenticationRequest(
            reason: "Test authentication",
            policy: .highSecurity,
            timestamp: timestamp
        )

        #expect(request.reason == "Test authentication")
        #expect(request.policy == .highSecurity)
        #expect(request.timestamp == timestamp)
    }

    @Test("AuthenticationRequest uses default values")
    func authenticationRequestDefaults() {
        let request = AuthenticationRequest(reason: "Test")

        #expect(request.reason == "Test")
        #expect(request.policy == .standard)
        // timestamp should be recent
        #expect(abs(request.timestamp.timeIntervalSinceNow) < 1)
    }

    @Test("AuthenticationPolicy initializes with defaults")
    func authenticationPolicyDefaults() {
        let policy = AuthenticationPolicy()

        #expect(policy.requireBiometric == false)
        #expect(policy.allowPasswordFallback == true)
        #expect(policy.requireRecentAuthentication == false)
        #expect(policy.cacheDuration == 300)
    }

    @Test("AuthenticationPolicy custom initialization")
    func authenticationPolicyCustom() {
        let policy = AuthenticationPolicy(
            requireBiometric: true,
            allowPasswordFallback: false,
            requireRecentAuthentication: true,
            cacheDuration: 60
        )

        #expect(policy.requireBiometric == true)
        #expect(policy.allowPasswordFallback == false)
        #expect(policy.requireRecentAuthentication == true)
        #expect(policy.cacheDuration == 60)
    }

    @Test("AuthenticationPolicy static configurations")
    func authenticationPolicyStatic() {
        // Test standard policy
        let standard = AuthenticationPolicy.standard
        #expect(standard.requireBiometric == false)
        #expect(standard.allowPasswordFallback == true)
        #expect(standard.cacheDuration == 300)

        // Test high security policy
        let highSec = AuthenticationPolicy.highSecurity
        #expect(highSec.requireBiometric == true)
        #expect(highSec.allowPasswordFallback == false)
        #expect(highSec.requireRecentAuthentication == true)
        #expect(highSec.cacheDuration == 60)
    }

    @Test("AuthenticationResult success detection")
    func authenticationResultSuccess() {
        let success = AuthenticationSuccess(method: .touchID)
        let successResult = AuthenticationResult.success(success)
        let failureResult = AuthenticationResult.failure(.biometryNotAvailable)
        let cancelledResult = AuthenticationResult.cancelled

        #expect(successResult.isSuccess == true)
        #expect(failureResult.isSuccess == false)
        #expect(cancelledResult.isSuccess == false)
    }

    @Test("AuthenticationSuccess initialization")
    func authenticationSuccessInit() {
        let timestamp = Date()
        let success = AuthenticationSuccess(
            authenticatedAt: timestamp,
            method: .faceID,
            cached: true
        )

        #expect(success.authenticatedAt == timestamp)
        #expect(success.method == .faceID)
        #expect(success.cached == true)
    }

    @Test("AuthenticationSuccess default values")
    func authenticationSuccessDefaults() {
        let success = AuthenticationSuccess(method: .password)

        #expect(success.method == .password)
        #expect(success.cached == false)
        #expect(abs(success.authenticatedAt.timeIntervalSinceNow) < 1)
    }

    @Test("AuthenticationMethod raw values")
    func authenticationMethodRawValues() {
        #expect(AuthenticationMethod.touchID.rawValue == "TouchID")
        #expect(AuthenticationMethod.faceID.rawValue == "FaceID")
        #expect(AuthenticationMethod.password.rawValue == "Password")
        #expect(AuthenticationMethod.cached.rawValue == "Cached")
    }

    @Test("AuthenticationFailure user messages")
    func authenticationFailureMessages() {
        #expect(AuthenticationFailure.biometryNotAvailable.userMessage.localizedCaseInsensitiveContains("biometric"))
        #expect(AuthenticationFailure.biometryNotEnrolled.userMessage.localizedCaseInsensitiveContains("enrolled"))
        #expect(AuthenticationFailure.biometryLockout.userMessage.localizedCaseInsensitiveContains("locked"))
        #expect(AuthenticationFailure.passcodeNotSet.userMessage.localizedCaseInsensitiveContains("passcode"))

        let futureDate = Date().addingTimeInterval(300)
        let rateLimited = AuthenticationFailure.rateLimited(untilDate: futureDate)
        #expect(rateLimited.userMessage.localizedCaseInsensitiveContains("attempt"))

        let invalidRequest = AuthenticationFailure.invalidRequest(reason: "test reason")
        #expect(invalidRequest.userMessage.contains("test reason"))

        let systemError = AuthenticationFailure.systemError(description: "test error")
        #expect(systemError.userMessage.contains("test error"))
    }

    @Test("BiometricAvailability initialization")
    func biometricAvailabilityInit() {
        // Available biometric
        let available = BiometricAvailability(
            isAvailable: true,
            biometricType: .touchID,
            unavailableReason: nil
        )
        #expect(available.isAvailable == true)
        #expect(available.biometricType == .touchID)
        #expect(available.unavailableReason == nil)

        // Unavailable biometric
        let unavailable = BiometricAvailability(
            isAvailable: false,
            biometricType: nil,
            unavailableReason: "Hardware not available"
        )
        #expect(unavailable.isAvailable == false)
        #expect(unavailable.biometricType == nil)
        #expect(unavailable.unavailableReason == "Hardware not available")
    }

    @Test("BiometricType raw values")
    func biometricTypeRawValues() {
        #expect(BiometricType.touchID.rawValue == "TouchID")
        #expect(BiometricType.faceID.rawValue == "FaceID")
        #expect(BiometricType.opticID.rawValue == "OpticID")
    }

    @Test("AuthenticationAttempt initialization")
    func authenticationAttemptInit() {
        let timestamp = Date()
        let attempt = AuthenticationAttempt(
            timestamp: timestamp,
            success: true,
            method: .touchID,
            reason: "Test authentication"
        )

        #expect(attempt.timestamp == timestamp)
        #expect(attempt.success == true)
        #expect(attempt.method == .touchID)
        #expect(attempt.reason == "Test authentication")
    }

    @Test("AuthenticationAttempt without method")
    func authenticationAttemptWithoutMethod() {
        let attempt = AuthenticationAttempt(
            timestamp: Date(),
            success: false,
            reason: "Failed attempt"
        )

        #expect(attempt.success == false)
        #expect(attempt.method == nil)
        #expect(attempt.reason == "Failed attempt")
    }

    @Test("AuthenticationSecurityConfig defaults")
    func authenticationSecurityConfigDefaults() {
        let config = AuthenticationSecurityConfig()

        #expect(config.maxFailedAttempts == 3)
        #expect(config.rateLimitDuration == 30)
        #expect(config.maxReasonLength == 200)
        #expect(config.logAuthenticationAttempts == true)
    }

    @Test("AuthenticationSecurityConfig custom values")
    func authenticationSecurityConfigCustom() {
        let config = AuthenticationSecurityConfig(
            maxFailedAttempts: 5,
            rateLimitDuration: 120,
            maxReasonLength: 500,
            logAuthenticationAttempts: false
        )

        #expect(config.maxFailedAttempts == 5)
        #expect(config.rateLimitDuration == 120)
        #expect(config.maxReasonLength == 500)
        #expect(config.logAuthenticationAttempts == false)
    }

    @Test("AuthenticationSecurityConfig static configurations")
    func authenticationSecurityConfigStatic() {
        // Test default config
        let defaultConfig = AuthenticationSecurityConfig.defaultConfig
        #expect(defaultConfig.maxFailedAttempts == 3)
        #expect(defaultConfig.rateLimitDuration == 30)

        // Test high security config
        let highSecConfig = AuthenticationSecurityConfig.highSecurity
        #expect(highSecConfig.maxFailedAttempts == 2)
        #expect(highSecConfig.rateLimitDuration == 60)
        #expect(highSecConfig.maxReasonLength == 100)
        #expect(highSecConfig.logAuthenticationAttempts == true)
    }

    @Test("All authentication enums are equatable")
    func authenticationEnumsEquatable() {
        // AuthenticationMethod
        #expect(AuthenticationMethod.touchID == AuthenticationMethod.touchID)
        #expect(AuthenticationMethod.touchID != AuthenticationMethod.faceID)

        // BiometricType
        #expect(BiometricType.touchID == BiometricType.touchID)
        #expect(BiometricType.touchID != BiometricType.faceID)

        // AuthenticationFailure
        #expect(AuthenticationFailure.biometryNotAvailable == AuthenticationFailure.biometryNotAvailable)
        #expect(AuthenticationFailure.biometryNotAvailable != AuthenticationFailure.biometryNotEnrolled)

        let date1 = Date()
        let date2 = Date().addingTimeInterval(60)
        #expect(AuthenticationFailure.rateLimited(untilDate: date1) == AuthenticationFailure.rateLimited(untilDate: date1))
        #expect(AuthenticationFailure.rateLimited(untilDate: date1) != AuthenticationFailure.rateLimited(untilDate: date2))

        #expect(AuthenticationFailure.invalidRequest(reason: "test") == AuthenticationFailure.invalidRequest(reason: "test"))
        #expect(AuthenticationFailure.invalidRequest(reason: "test1") != AuthenticationFailure.invalidRequest(reason: "test2"))
    }

    // MARK: - PowerMonitor Domain Model Tests

    @Test("PowerStateChange initialization with connection change")
    func powerStateChangeConnectionChange() {
        let previousState = PowerStateInfo(isConnected: false, batteryLevel: 50, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 50, timestamp: Date())

        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        #expect(change.previousState == previousState)
        #expect(change.currentState == currentState)
        #expect(change.changeType == .connected)
    }

    @Test("PowerStateChange initialization with disconnection")
    func powerStateChangeDisconnection() {
        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 85, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 85, timestamp: Date())

        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        #expect(change.previousState == previousState)
        #expect(change.currentState == currentState)
        #expect(change.changeType == .disconnected)
    }

    @Test("PowerStateChange initialization with battery level change")
    func powerStateChangeBatteryLevelChange() {
        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 75, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 90, timestamp: Date())

        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        #expect(change.previousState == previousState)
        #expect(change.currentState == currentState)
        #expect(change.changeType == .batteryLevelChanged(from: 75, to: 90))
    }

    @Test("PowerStateChange initialization with charging state change")
    func powerStateChangeChargingStateChange() {
        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 60, isCharging: false, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 60, isCharging: true, timestamp: Date())

        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        #expect(change.previousState == previousState)
        #expect(change.currentState == currentState)
        #expect(change.changeType == .chargingStateChanged(isCharging: true))
    }

    @Test("PowerStateChange initialization with no change fallback")
    func powerStateChangeNoChangeFallback() {
        let timestamp = Date()
        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: timestamp)
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: timestamp)

        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        #expect(change.previousState == previousState)
        #expect(change.currentState == currentState)
        #expect(change.changeType == .connected) // Fallback to current connection state
    }

    @Test("PowerStateChange ChangeType is Equatable")
    func powerStateChangeTypeEquatable() {
        let connected1 = PowerStateChange.ChangeType.connected
        let connected2 = PowerStateChange.ChangeType.connected
        let disconnected = PowerStateChange.ChangeType.disconnected

        #expect(connected1 == connected2)
        #expect(connected1 != disconnected)

        let batteryChange1 = PowerStateChange.ChangeType.batteryLevelChanged(from: 50, to: 75)
        let batteryChange2 = PowerStateChange.ChangeType.batteryLevelChanged(from: 50, to: 75)
        let batteryChange3 = PowerStateChange.ChangeType.batteryLevelChanged(from: 60, to: 75)

        #expect(batteryChange1 == batteryChange2)
        #expect(batteryChange1 != batteryChange3)

        let chargingChange1 = PowerStateChange.ChangeType.chargingStateChanged(isCharging: true)
        let chargingChange2 = PowerStateChange.ChangeType.chargingStateChanged(isCharging: true)
        let chargingChange3 = PowerStateChange.ChangeType.chargingStateChanged(isCharging: false)

        #expect(chargingChange1 == chargingChange2)
        #expect(chargingChange1 != chargingChange3)
    }

    // MARK: - SecurityAnalysis Tests

    @Test("SecurityAnalysis initialization")
    func securityAnalysisInit() {
        let actions: [SecurityAnalysis.SecurityAction] = [.lockScreen, .notify]
        let analysis = SecurityAnalysis(
            threatLevel: .high,
            reason: "Power disconnected unexpectedly",
            recommendedActions: actions
        )

        #expect(analysis.threatLevel == .high)
        #expect(analysis.reason == "Power disconnected unexpectedly")
        #expect(analysis.recommendedActions == actions)
    }

    @Test("SecurityAnalysis initialization with defaults")
    func securityAnalysisDefaults() {
        let analysis = SecurityAnalysis(
            threatLevel: .medium,
            reason: "Battery level dropped significantly"
        )

        #expect(analysis.threatLevel == .medium)
        #expect(analysis.reason == "Battery level dropped significantly")
        #expect(analysis.recommendedActions.isEmpty)
    }

    @Test("SecurityAnalysis ThreatLevel comparison")
    func securityAnalysisThreatLevelComparison() {
        #expect(SecurityAnalysis.ThreatLevel.none < SecurityAnalysis.ThreatLevel.low)
        #expect(SecurityAnalysis.ThreatLevel.low < SecurityAnalysis.ThreatLevel.medium)
        #expect(SecurityAnalysis.ThreatLevel.medium < SecurityAnalysis.ThreatLevel.high)

        #expect(SecurityAnalysis.ThreatLevel.high > SecurityAnalysis.ThreatLevel.medium)
        #expect(SecurityAnalysis.ThreatLevel.medium > SecurityAnalysis.ThreatLevel.low)
        #expect(SecurityAnalysis.ThreatLevel.low > SecurityAnalysis.ThreatLevel.none)

        #expect(SecurityAnalysis.ThreatLevel.medium == SecurityAnalysis.ThreatLevel.medium)
        #expect(SecurityAnalysis.ThreatLevel.none != SecurityAnalysis.ThreatLevel.high)
    }

    @Test("SecurityAnalysis ThreatLevel raw values")
    func securityAnalysisThreatLevelRawValues() {
        #expect(SecurityAnalysis.ThreatLevel.none.rawValue == 0)
        #expect(SecurityAnalysis.ThreatLevel.low.rawValue == 1)
        #expect(SecurityAnalysis.ThreatLevel.medium.rawValue == 2)
        #expect(SecurityAnalysis.ThreatLevel.high.rawValue == 3)
    }

    @Test("SecurityAnalysis SecurityAction cases")
    func securityAnalysisSecurityActionCases() {
        let actions: [SecurityAnalysis.SecurityAction] = [
            .none,
            .notify,
            .lockScreen,
            .shutdown,
            .custom("Custom security measure")
        ]

        #expect(actions.count == 5)
        #expect(actions.contains(.none))
        #expect(actions.contains(.notify))
        #expect(actions.contains(.lockScreen))
        #expect(actions.contains(.shutdown))
        #expect(actions.contains(.custom("Custom security measure")))
    }

    @Test("SecurityAnalysis SecurityAction is Equatable")
    func securityAnalysisSecurityActionEquatable() {
        let none1 = SecurityAnalysis.SecurityAction.none
        let none2 = SecurityAnalysis.SecurityAction.none
        let notify = SecurityAnalysis.SecurityAction.notify

        #expect(none1 == none2)
        #expect(none1 != notify)

        let custom1 = SecurityAnalysis.SecurityAction.custom("test")
        let custom2 = SecurityAnalysis.SecurityAction.custom("test")
        let custom3 = SecurityAnalysis.SecurityAction.custom("different")

        #expect(custom1 == custom2)
        #expect(custom1 != custom3)
        #expect(custom1 != .lockScreen)
    }

    // MARK: - PowerMonitorConfiguration Tests

    @Test("PowerMonitorConfiguration initialization with defaults")
    func powerMonitorConfigurationDefaults() {
        let config = PowerMonitorConfiguration()

        #expect(config.pollingInterval == 0.1)
        #expect(config.useSystemNotifications == true)
        #expect(config.debounceInterval == 0.5)
    }

    @Test("PowerMonitorConfiguration custom initialization")
    func powerMonitorConfigurationCustom() {
        let config = PowerMonitorConfiguration(
            pollingInterval: 1.0,
            useSystemNotifications: false,
            debounceInterval: 2.0
        )

        #expect(config.pollingInterval == 1.0)
        #expect(config.useSystemNotifications == false)
        #expect(config.debounceInterval == 2.0)
    }

    // MARK: - AutoArm Domain Model Tests

    @Test("AutoArmConfiguration initializes with defaults")
    func autoArmConfigurationDefaults() {
        let config = AutoArmConfiguration()

        #expect(config.isEnabled == false)
        #expect(config.armByLocation == false)
        #expect(config.armOnUntrustedNetwork == false)
        #expect(config.armCooldownPeriod == 30)
        #expect(config.notifyBeforeArming == true)
        #expect(config.notificationDelay == 2.0)
    }

    @Test("AutoArmConfiguration custom initialization")
    func autoArmConfigurationCustom() {
        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: true,
            armCooldownPeriod: 60,
            notifyBeforeArming: false,
            notificationDelay: 5.0
        )

        #expect(config.isEnabled == true)
        #expect(config.armByLocation == true)
        #expect(config.armOnUntrustedNetwork == true)
        #expect(config.armCooldownPeriod == 60)
        #expect(config.notifyBeforeArming == false)
        #expect(config.notificationDelay == 5.0)
    }

    @Test("AutoArmConfiguration validates minimum values")
    func autoArmConfigurationValidation() {
        let config = AutoArmConfiguration(
            armCooldownPeriod: -10, // Should be clamped to 0
            notificationDelay: -5   // Should be clamped to 0
        )

        #expect(config.armCooldownPeriod == 0)
        #expect(config.notificationDelay == 0)
    }

    @Test("AutoArmConfiguration default static value")
    func autoArmConfigurationDefault() {
        let defaultConfig = AutoArmConfiguration.defaultConfig

        #expect(defaultConfig.isEnabled == false)
        #expect(defaultConfig.armByLocation == false)
        #expect(defaultConfig.armOnUntrustedNetwork == false)
    }

    @Test("AutoArmTrigger descriptions")
    func autoArmTriggerDescriptions() {
        // Test with named location
        let namedLocation = AutoArmTrigger.leftTrustedLocation(name: "Home")
        #expect(namedLocation.description == "Left trusted location: Home")

        // Test without named location  
        let unnamedLocation = AutoArmTrigger.leftTrustedLocation(name: nil)
        #expect(unnamedLocation.description == "Left trusted location")

        // Test network triggers
        let untrusted = AutoArmTrigger.enteredUntrustedNetwork(ssid: "PublicWiFi")
        #expect(untrusted.description == "Connected to untrusted network: PublicWiFi")

        let disconnected = AutoArmTrigger.disconnectedFromTrustedNetwork(ssid: "HomeWiFi")
        #expect(disconnected.description == "Disconnected from trusted network: HomeWiFi")

        let lostConnectivity = AutoArmTrigger.lostNetworkConnectivity
        #expect(lostConnectivity.description == "Lost network connectivity")

        let manual = AutoArmTrigger.manual(reason: "User triggered")
        #expect(manual.description == "User triggered")
    }

    @Test("AutoArmEvent initialization")
    func autoArmEventInit() {
        let trigger = AutoArmTrigger.leftTrustedLocation(name: "Office")
        let timestamp = Date()
        let config = AutoArmConfiguration.defaultConfig

        let event = AutoArmEvent(
            trigger: trigger,
            timestamp: timestamp,
            configuration: config
        )

        #expect(event.trigger == trigger)
        #expect(event.timestamp == timestamp)
        #expect(event.configuration == config)
    }

    @Test("AutoArmEvent default timestamp")
    func autoArmEventDefaultTimestamp() {
        let trigger = AutoArmTrigger.manual(reason: "Test")
        let config = AutoArmConfiguration.defaultConfig

        let event = AutoArmEvent(trigger: trigger, configuration: config)

        #expect(event.trigger == trigger)
        #expect(event.configuration == config)
        #expect(abs(event.timestamp.timeIntervalSinceNow) < 1)
    }

    @Test("AutoArmDecision shouldArm detection")
    func autoArmDecisionShouldArm() {
        let armDecision = AutoArmDecision.arm(reason: "Left trusted location")
        let skipDecision = AutoArmDecision.skip(reason: .disabled)

        #expect(armDecision.shouldArm == true)
        #expect(skipDecision.shouldArm == false)
    }

    @Test("AutoArmSkipReason descriptions")
    func autoArmSkipReasonDescriptions() {
        #expect(AutoArmSkipReason.disabled.description == "Auto-arm is disabled")
        #expect(AutoArmSkipReason.alreadyArmed.description == "System is already armed")
        #expect(AutoArmSkipReason.conditionNotMet.description == "Auto-arm conditions not met")

        let futureDate = Date().addingTimeInterval(300)
        let tempDisabled = AutoArmSkipReason.temporarilyDisabled(until: futureDate)
        #expect(tempDisabled.description.localizedCaseInsensitiveContains("temporarily disabled"))

        let cooldown = AutoArmSkipReason.cooldownPeriod(until: futureDate)
        #expect(cooldown.description.localizedCaseInsensitiveContains("cooldown"))
    }

    @Test("TrustedLocationDomain initialization")
    func trustedLocationInit() {
        let id = UUID()
        let location = TrustedLocationDomain(
            id: id,
            name: "Home",
            latitude: 37.7749,
            longitude: -122.4194,
            radius: 150.0
        )

        #expect(location.id == id)
        #expect(location.name == "Home")
        #expect(location.latitude == 37.7749)
        #expect(location.longitude == -122.4194)
        #expect(location.radius == 150.0)
    }

    @Test("TrustedLocationDomain default values")
    func trustedLocationDefaults() {
        let location = TrustedLocationDomain(
            name: "Office",
            latitude: 40.7128,
            longitude: -74.0060
        )

        #expect(location.name == "Office")
        #expect(location.latitude == 40.7128)
        #expect(location.longitude == -74.0060)
        #expect(location.radius == 100.0) // Default radius
        #expect(location.id != UUID()) // Should generate new UUID
    }

    @Test("TrustedLocationDomain minimum radius validation")
    func trustedLocationMinimumRadius() {
        let location = TrustedLocationDomain(
            name: "Test",
            latitude: 0,
            longitude: 0,
            radius: 5.0 // Below minimum of 10
        )

        #expect(location.radius == 10.0) // Should be clamped to minimum
    }

    @Test("TrustedNetwork initialization")
    func trustedNetworkInit() {
        let timestamp = Date()
        let network = TrustedNetwork(
            ssid: "HomeWiFi",
            addedDate: timestamp
        )

        #expect(network.ssid == "HomeWiFi")
        #expect(network.addedDate == timestamp)
    }

    @Test("TrustedNetwork default date")
    func trustedNetworkDefaultDate() {
        let network = TrustedNetwork(ssid: "OfficeWiFi")

        #expect(network.ssid == "OfficeWiFi")
        #expect(abs(network.addedDate.timeIntervalSinceNow) < 1)
    }

    @Test("NetworkInfo initialization")
    func networkInfoInit() {
        let networkInfo = NetworkInfo(
            isConnected: true,
            currentSSID: "TestNetwork",
            isTrusted: true
        )

        #expect(networkInfo.isConnected == true)
        #expect(networkInfo.currentSSID == "TestNetwork")
        #expect(networkInfo.isTrusted == true)
    }

    @Test("NetworkInfo default values")
    func networkInfoDefaults() {
        let networkInfo = NetworkInfo(isConnected: false)

        #expect(networkInfo.isConnected == false)
        #expect(networkInfo.currentSSID == nil)
        #expect(networkInfo.isTrusted == false)
    }

    @Test("NetworkChangeEvent cases")
    func networkChangeEventCases() {
        let connected = NetworkChangeEvent.connectedToNetwork(ssid: "WiFi", trusted: true)
        let disconnected = NetworkChangeEvent.disconnectedFromNetwork(ssid: "WiFi", trusted: false)
        let connectivityChanged = NetworkChangeEvent.connectivityChanged(isConnected: false)

        // Test basic enum functionality
        #expect(connected != disconnected)
        #expect(disconnected != connectivityChanged)
        #expect(connected != connectivityChanged)
    }

    @Test("AutoArmStatus initialization")
    func autoArmStatusInit() {
        let timestamp = Date()
        let config = AutoArmConfiguration.defaultConfig
        let trigger = AutoArmTrigger.manual(reason: "Test")
        let lastEvent = AutoArmEvent(trigger: trigger, timestamp: timestamp, configuration: config)
        let networkInfo = NetworkInfo(isConnected: true, currentSSID: "Test", isTrusted: true)
        let conditions = AutoArmConditions(
            isInTrustedLocation: true,
            currentNetwork: networkInfo,
            shouldAutoArm: false
        )

        let status = AutoArmStatus(
            isEnabled: true,
            isMonitoring: true,
            isTemporarilyDisabled: false,
            temporaryDisableUntil: timestamp,
            lastEvent: lastEvent,
            currentConditions: conditions
        )

        #expect(status.isEnabled == true)
        #expect(status.isMonitoring == true)
        #expect(status.isTemporarilyDisabled == false)
        #expect(status.temporaryDisableUntil == timestamp)
        #expect(status.lastEvent == lastEvent)
        #expect(status.currentConditions == conditions)
    }

    @Test("AutoArmConditions initialization")
    func autoArmConditionsInit() {
        let networkInfo = NetworkInfo(isConnected: false)
        let conditions = AutoArmConditions(
            isInTrustedLocation: false,
            currentNetwork: networkInfo,
            shouldAutoArm: true
        )

        #expect(conditions.isInTrustedLocation == false)
        #expect(conditions.currentNetwork == networkInfo)
        #expect(conditions.shouldAutoArm == true)
    }

    @Test("AutoArm enums are equatable")
    func autoArmEnumsEquatable() {
        // AutoArmTrigger
        let trigger1 = AutoArmTrigger.leftTrustedLocation(name: "Home")
        let trigger2 = AutoArmTrigger.leftTrustedLocation(name: "Home")
        let trigger3 = AutoArmTrigger.leftTrustedLocation(name: "Office")

        #expect(trigger1 == trigger2)
        #expect(trigger1 != trigger3)

        // AutoArmDecision
        let decision1 = AutoArmDecision.arm(reason: "Test")
        let decision2 = AutoArmDecision.arm(reason: "Test")
        let decision3 = AutoArmDecision.arm(reason: "Different")

        #expect(decision1 == decision2)
        #expect(decision1 != decision3)

        // AutoArmSkipReason
        let skip1 = AutoArmSkipReason.disabled
        let skip2 = AutoArmSkipReason.disabled
        let skip3 = AutoArmSkipReason.alreadyArmed

        #expect(skip1 == skip2)
        #expect(skip1 != skip3)

        let date1 = Date()
        let date2 = Date().addingTimeInterval(60)
        let temp1 = AutoArmSkipReason.temporarilyDisabled(until: date1)
        let temp2 = AutoArmSkipReason.temporarilyDisabled(until: date1)
        let temp3 = AutoArmSkipReason.temporarilyDisabled(until: date2)

        #expect(temp1 == temp2)
        #expect(temp1 != temp3)

        // NetworkChangeEvent
        let net1 = NetworkChangeEvent.connectedToNetwork(ssid: "WiFi", trusted: true)
        let net2 = NetworkChangeEvent.connectedToNetwork(ssid: "WiFi", trusted: true)
        let net3 = NetworkChangeEvent.connectedToNetwork(ssid: "WiFi", trusted: false)

        #expect(net1 == net2)
        #expect(net1 != net3)
    }
}
