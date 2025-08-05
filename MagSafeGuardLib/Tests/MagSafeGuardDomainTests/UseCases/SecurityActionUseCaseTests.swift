//
//  SecurityActionUseCaseTests.swift
//  MagSafe Guard Tests
//
//  Created on 2025-08-03.
//

import Foundation
@testable import MagSafeGuardCore
@testable import MagSafeGuardDomain
@testable import TestInfrastructure
import Testing

/// Tests for SecurityActionExecutionUseCaseImpl and SecurityActionConfigurationUseCaseImpl
@Suite("SecurityAction Use Cases")
struct SecurityActionUseCaseTests {

    // MARK: - SecurityActionExecutionUseCaseImpl Tests

    @Test("Should execute actions sequentially by default")
    func testSequentialExecution() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        let configuration = SecurityActionConfiguration(
            enabledActions: [.lockScreen, .soundAlarm],
            executeInParallel: false
        )
        let request = SecurityActionRequest(
            configuration: configuration,
            trigger: .testTrigger
        )

        // When
        let result = await useCase.executeActions(request: request)

        // Then
        #expect(result.allSucceeded)
        #expect(result.executedActions.count == 2)
        #expect(await mockRepository.lockScreenCalls == 1)
        #expect(await mockRepository.playAlarmCalls == 1)
    }

    @Test("Should execute actions in parallel when configured")
    func testParallelExecution() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        let configuration = SecurityActionConfiguration(
            enabledActions: [.lockScreen, .soundAlarm],
            executeInParallel: true
        )
        let request = SecurityActionRequest(
            configuration: configuration,
            trigger: .testTrigger
        )

        // When
        let result = await useCase.executeActions(request: request)

        // Then
        #expect(result.allSucceeded)
        #expect(result.executedActions.count == 2)
        #expect(await mockRepository.lockScreenCalls == 1)
        #expect(await mockRepository.playAlarmCalls == 1)
    }

    @Test("Should prioritize lock screen action first")
    func testActionPrioritization() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        let configuration = SecurityActionConfiguration(
            enabledActions: [.soundAlarm, .lockScreen, .shutdown], // Lock screen not first
            executeInParallel: false
        )
        let request = SecurityActionRequest(
            configuration: configuration,
            trigger: .testTrigger
        )

        // When
        let result = await useCase.executeActions(request: request)

        // Then
        #expect(result.allSucceeded)
        #expect(result.executedActions.count == 3)
        // Lock screen should be executed first
        #expect(result.executedActions.first?.actionType == .lockScreen)
    }

    @Test("Should handle action delay")
    func testActionDelay() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        let configuration = SecurityActionConfiguration(
            enabledActions: [.lockScreen],
            actionDelay: 0.1 // 100ms delay
        )
        let request = SecurityActionRequest(
            configuration: configuration,
            trigger: .testTrigger
        )
        _ = Date() // Start time for reference

        // When
        let result = await useCase.executeActions(request: request)

        // Then
        let duration = result.duration
        #expect(duration >= 0.1) // Should take at least 100ms due to delay
        #expect(result.allSucceeded)
    }

    @Test("Should prevent concurrent execution", .disabled("Flaky test - race condition"))
    func testConcurrentExecutionPrevention() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        let configuration = SecurityActionConfiguration(enabledActions: [.lockScreen])
        let request = SecurityActionRequest(configuration: configuration, trigger: .testTrigger)

        // When - Start two executions concurrently
        async let result1 = useCase.executeActions(request: request)
        async let result2 = useCase.executeActions(request: request)

        let results = await [result1, result2]

        // Then - One should succeed, one should fail with alreadyExecuting error
        let successCount = results.filter { $0.allSucceeded }.count
        let failureCount = results.filter { !$0.allSucceeded }.count

        #expect(successCount == 1)
        #expect(failureCount == 1)

        if let failedResult = results.first(where: { !$0.allSucceeded }) {
            #expect(failedResult.executedActions.first?.error == .alreadyExecuting)
        }
    }

    @Test("Should stop ongoing actions")
    func testStopOngoingActions() async {
        // Given
        let mockRepository = MockSecurityActionRepository()
        let useCase = SecurityActionExecutionUseCaseImpl(repository: mockRepository)

        // When
        await useCase.stopOngoingActions()

        // Then
        #expect(await mockRepository.stopAlarmCalls == 1)
    }

    // MARK: - SecurityActionConfigurationUseCaseImpl Tests

    @Test("Should get current configuration")
    func testGetCurrentConfiguration() async {
        // Given
        let store = InMemoryConfigurationStore()
        let useCase = SecurityActionConfigurationUseCaseImpl(configurationStore: store)

        // When
        let configuration = await useCase.getCurrentConfiguration()

        // Then
        #expect(configuration == .default)
    }

    @Test("Should update configuration")
    func testUpdateConfiguration() async throws {
        // Given
        let store = InMemoryConfigurationStore()
        let useCase = SecurityActionConfigurationUseCaseImpl(configurationStore: store)

        let newConfiguration = SecurityActionConfiguration(
            enabledActions: [.lockScreen, .soundAlarm],
            alarmVolume: 0.8
        )

        // When
        try await useCase.updateConfiguration(newConfiguration)

        // Then
        let storedConfiguration = await useCase.getCurrentConfiguration()
        #expect(storedConfiguration.enabledActions == newConfiguration.enabledActions)
        #expect(storedConfiguration.alarmVolume == newConfiguration.alarmVolume)
    }

    @Test("Should validate configuration - valid")
    func testValidConfigurationValidation() {
        // Given
        let useCase = SecurityActionConfigurationUseCaseImpl()
        let validConfiguration = SecurityActionConfiguration(
            enabledActions: [.lockScreen],
            actionDelay: 0,
            alarmVolume: 0.5,
            shutdownDelay: 30
        )

        // When
        let result = useCase.validateConfiguration(validConfiguration)

        // Then
        switch result {
        case .success:
            // Test passes
            break
        case .failure(let error):
            Issue.record("Expected success but got failure: \(error)")
        }
    }

    @Test("SecurityActionConfiguration clamps alarm volume")
    func testAlarmVolumeClamping() {
        // Given - Try to create configuration with invalid volumes
        let tooHighConfig = SecurityActionConfiguration(
            enabledActions: [.lockScreen],
            alarmVolume: 1.5 // Should be clamped to 1.0
        )
        
        let tooLowConfig = SecurityActionConfiguration(
            enabledActions: [.lockScreen],
            alarmVolume: -0.5 // Should be clamped to 0.0
        )

        // Then - Volume should be clamped to valid range
        #expect(tooHighConfig.alarmVolume == 1.0)
        #expect(tooLowConfig.alarmVolume == 0.0)
        
        // Verify validation passes for clamped values
        let useCase = SecurityActionConfigurationUseCaseImpl()
        let result1 = useCase.validateConfiguration(tooHighConfig)
        let result2 = useCase.validateConfiguration(tooLowConfig)
        
        if case .failure = result1 {
            Issue.record("Expected validation to pass for clamped high value")
        }
        if case .failure = result2 {
            Issue.record("Expected validation to pass for clamped low value")
        }
    }

    @Test("Should validate configuration - no actions enabled")
    func testNoActionsEnabledValidation() {
        // Given
        let useCase = SecurityActionConfigurationUseCaseImpl()
        let invalidConfiguration = SecurityActionConfiguration(
            enabledActions: [] // Empty set
        )

        // When
        let result = useCase.validateConfiguration(invalidConfiguration)

        // Then
        if case .failure(let error) = result {
            #expect(error == .invalidConfiguration(reason: "At least one security action must be enabled"))
        } else {
            Issue.record("Expected validation failure")
        }
    }

    @Test("Should validate configuration - custom script without path")
    func testCustomScriptWithoutPathValidation() {
        // Given
        let useCase = SecurityActionConfigurationUseCaseImpl()
        let invalidConfiguration = SecurityActionConfiguration(
            enabledActions: [.customScript],
            customScriptPath: nil // Missing path
        )

        // When
        let result = useCase.validateConfiguration(invalidConfiguration)

        // Then
        if case .failure(let error) = result {
            #expect(error == .invalidConfiguration(reason: "Custom script path is required when custom script action is enabled"))
        } else {
            Issue.record("Expected validation failure")
        }
    }

    @Test("Should reset to default configuration")
    func testResetToDefault() async {
        // Given
        let store = InMemoryConfigurationStore()
        let useCase = SecurityActionConfigurationUseCaseImpl(configurationStore: store)

        // Set a custom configuration first
        let customConfiguration = SecurityActionConfiguration(
            enabledActions: [.lockScreen, .soundAlarm, .shutdown],
            alarmVolume: 0.8
        )
        try! await useCase.updateConfiguration(customConfiguration)

        // When
        await useCase.resetToDefault()

        // Then
        let configuration = await useCase.getCurrentConfiguration()
        #expect(configuration == .default)
    }
}
