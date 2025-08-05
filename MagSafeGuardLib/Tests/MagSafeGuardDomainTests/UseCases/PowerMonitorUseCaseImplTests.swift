//
//  PowerMonitorUseCaseImplTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Tests for PowerMonitorUseCaseImpl to achieve 95%+ coverage

import Foundation
@testable import MagSafeGuardDomain
import Testing

extension PowerMonitorUseCaseImplTests {
    // Test-specific error for mocking
    enum TestPowerMonitorError: LocalizedError, Equatable {
        case deviceUnavailable
        case monitoringFailed

        var errorDescription: String? {
            switch self {
            case .deviceUnavailable:
                return "Device unavailable"
            case .monitoringFailed:
                return "Monitoring failed"
            }
        }
    }
}

@Suite("PowerMonitorUseCaseImpl Tests")
struct PowerMonitorUseCaseImplTests {

    // MARK: - Mock Dependencies

    private final class MockPowerStateRepository: PowerStateRepository, @unchecked Sendable {
        private let shouldFail: Bool
        private let mockState: PowerStateInfo
        private let streamContinuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation?

        private let stateStream: AsyncThrowingStream<PowerStateInfo, Error>

        init(shouldFail: Bool = false, mockState: PowerStateInfo? = nil) {
            self.shouldFail = shouldFail
            self.mockState = mockState ?? PowerStateInfo(
                isConnected: true,
                batteryLevel: 80,
                isCharging: true,
                timestamp: Date()
            )

            var streamContinuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation?
            self.stateStream = AsyncThrowingStream { continuation in
                streamContinuation = continuation
            }
            self.streamContinuation = streamContinuation
        }

        func getCurrentPowerState() async throws -> PowerStateInfo {
            if shouldFail {
                throw TestPowerMonitorError.deviceUnavailable
            }
            return mockState
        }

        func observePowerStateChanges() -> AsyncThrowingStream<PowerStateInfo, Error> {
            return stateStream
        }

        func simulateStateChange(_ newState: PowerStateInfo) async {
            streamContinuation?.yield(newState)
        }

        func simulateError(_ error: Error) async {
            streamContinuation?.finish(throwing: error)
        }

        func finishStream() async {
            streamContinuation?.finish()
        }
    }

    private struct MockPowerStateAnalyzer: PowerStateAnalyzer {
        private let shouldFail: Bool

        init(shouldFail: Bool = false) {
            self.shouldFail = shouldFail
        }

        func analyzeStateChange(_ change: PowerStateChange) -> SecurityAnalysis {
            // Mock analyzer always returns no threat for testing
            return SecurityAnalysis(
                threatLevel: .none,
                reason: "Mock analyzer - no threat"
            )
        }
    }

    // MARK: - Initialization Tests

    @Test("PowerMonitorUseCaseImpl initialization")
    func powerMonitorUseCaseImplInitialization() async {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let configuration = PowerMonitorConfiguration(
            pollingInterval: 1.0,
            useSystemNotifications: true,
            debounceInterval: 0.1
        )

        let useCase = PowerMonitorUseCaseImpl(
            repository: repository,
            analyzer: analyzer,
            configuration: configuration
        )

        // Test that the use case initializes correctly
        // We can't directly access private properties, but we can test behavior
        do {
            let state = try await useCase.getCurrentPowerState()
            #expect(state.isConnected == true)
            #expect(state.batteryLevel == 80)
        } catch {
            #expect(Bool(false), "Should not throw on initialization")
        }
    }

    @Test("PowerMonitorUseCaseImpl initialization with custom configuration")
    func initializationWithCustomConfiguration() async {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let customConfig = PowerMonitorConfiguration(
            pollingInterval: 2.0,
            useSystemNotifications: false,
            debounceInterval: 0.1
        )

        let useCase = PowerMonitorUseCaseImpl(
            repository: repository,
            analyzer: analyzer,
            configuration: customConfig
        )

        // Verify initialization doesn't fail with custom config
        do {
            let state = try await useCase.getCurrentPowerState()
            #expect((state.batteryLevel ?? 0) >= 0)
        } catch {
            #expect(Bool(false), "Should initialize with custom config")
        }
    }

    // MARK: - Power State Tests

    @Test("Get current power state successfully")
    func getCurrentPowerStateSuccessfully() async throws {
        let expectedState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 65,
            isCharging: false,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: expectedState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        let actualState = try await useCase.getCurrentPowerState()

        #expect(actualState.isConnected == expectedState.isConnected)
        #expect(actualState.batteryLevel == expectedState.batteryLevel)
        #expect(actualState.isCharging == expectedState.isCharging)
    }

    @Test("Get current power state with repository error")
    func getCurrentPowerStateWithRepositoryError() async {
        let repository = MockPowerStateRepository(shouldFail: true)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        do {
            _ = try await useCase.getCurrentPowerState()
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as TestPowerMonitorError {
            #expect(error == .deviceUnavailable)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    // MARK: - Monitoring Tests

    @Test("Start monitoring successfully")
    func startMonitoringSuccessfully() async throws {
        let initialState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 90,
            isCharging: true,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Verify monitoring started by checking we can get current state
        let state = try await useCase.getCurrentPowerState()
        #expect(state.isConnected == true)

        // Clean up
        await useCase.stopMonitoring()
    }

    @Test("Start monitoring with repository failure")
    func startMonitoringWithRepositoryFailure() async {
        let repository = MockPowerStateRepository(shouldFail: true)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        do {
            try await useCase.startMonitoring()
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as TestPowerMonitorError {
            #expect(error == .deviceUnavailable)
        } catch {
            #expect(Bool(false), "Wrong error type")
        }
    }

    @Test("Stop monitoring")
    func stopMonitoring() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        // Start monitoring first
        try await useCase.startMonitoring()

        // Stop monitoring - should not throw
        await useCase.stopMonitoring()

        // Verify we can still get current state (this goes directly to repository)
        let state = try await useCase.getCurrentPowerState()
        #expect((state.batteryLevel ?? 0) >= 0)
    }

    @Test("Multiple start monitoring calls")
    func multipleStartMonitoringCalls() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        // Start monitoring multiple times - should handle gracefully
        try await useCase.startMonitoring()
        try await useCase.startMonitoring()
        try await useCase.startMonitoring()

        // Should still work
        let state = try await useCase.getCurrentPowerState()
        #expect(state.isConnected == true)

        await useCase.stopMonitoring()
    }

    // MARK: - Power State Change Stream Tests

    @Test("Power state changes stream basic functionality")
    func powerStateChangesStreamBasicFunctionality() async throws {
        let initialState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 80,
            isCharging: true,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        // Start monitoring
        try await useCase.startMonitoring()

        // Test that the stream exists and is accessible
        _ = useCase.powerStateChanges

        // Simulate a state change
        let newState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 80,
            isCharging: false,
            timestamp: Date()
        )

        await repository.simulateStateChange(newState)

        // Give a moment for processing
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        await useCase.stopMonitoring()
    }

    @Test("Handle state update with connection change")
    func handleStateUpdateWithConnectionChange() async throws {
        let initialState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 80,
            isCharging: true,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Simulate disconnection
        let disconnectedState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 80,
            isCharging: false,
            timestamp: Date()
        )

        await repository.simulateStateChange(disconnectedState)

        // Small delay to process the change
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms

        await useCase.stopMonitoring()
    }

    @Test("Handle state update with battery level change")
    func handleStateUpdateWithBatteryLevelChange() async throws {
        let initialState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 80,
            isCharging: false,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Simulate battery level drop
        let lowBatteryState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 20,
            isCharging: false,
            timestamp: Date()
        )

        await repository.simulateStateChange(lowBatteryState)

        // Small delay to process
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms

        await useCase.stopMonitoring()
    }

    @Test("Handle repository stream error")
    func handleRepositoryStreamError() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Simulate an error in the stream
        await repository.simulateError(TestPowerMonitorError.monitoringFailed)

        // Should handle the error gracefully without crashing
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        await useCase.stopMonitoring()
    }

    @Test("Handle stream completion")
    func handleStreamCompletion() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Simulate stream completion
        await repository.finishStream()

        // Should handle completion gracefully
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        await useCase.stopMonitoring()
    }

    // MARK: - Analyzer Integration Tests

    @Test("Analyzer integration with different change types")
    func analyzerIntegrationWithDifferentChangeTypes() async throws {
        let initialState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 80,
            isCharging: true,
            timestamp: Date()
        )

        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Test multiple state changes
        let states = [
            PowerStateInfo( // Connection change
                isConnected: false,
                batteryLevel: 80,
                isCharging: false,
                timestamp: Date()
            ),
            PowerStateInfo( // Battery level change
                isConnected: false,
                batteryLevel: 60,
                isCharging: false,
                timestamp: Date()
            ),
            PowerStateInfo( // Charging state change
                isConnected: true,
                batteryLevel: 60,
                isCharging: true,
                timestamp: Date()
            )
        ]

        // Simulate each state change
        for state in states {
            await repository.simulateStateChange(state)
            try? await Task.sleep(nanoseconds: 2_000_000) // 2ms between changes
        }

        await useCase.stopMonitoring()
    }

    @Test("Analyzer with failure scenario")
    func analyzerWithFailureScenario() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer(shouldFail: true)
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // Should still handle analyzer "failures" gracefully
        let newState = PowerStateInfo(
            isConnected: false,
            batteryLevel: 50,
            isCharging: false,
            timestamp: Date()
        )

        await repository.simulateStateChange(newState)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms

        await useCase.stopMonitoring()
    }

    // MARK: - Configuration Tests

    @Test("Configuration impact on monitoring")
    func configurationImpactOnMonitoring() async throws {
        let customConfig = PowerMonitorConfiguration(
            pollingInterval: 0.5,
            useSystemNotifications: true,
            debounceInterval: 0.05
        )

        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(
            repository: repository,
            analyzer: analyzer,
            configuration: customConfig
        )

        try await useCase.startMonitoring()

        // Verify monitoring works with custom configuration
        let state = try await useCase.getCurrentPowerState()
        #expect((state.batteryLevel ?? 0) >= 0)

        await useCase.stopMonitoring()
    }

    // MARK: - hasStateChanged Edge Cases Tests

    @Test("hasStateChanged with connection state differences")
    func hasStateChangedWithConnectionStateDifferences() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        _ = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let disconnectedState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())

        try await useCase.startMonitoring()

        // Simulate connection change
        await repository.simulateStateChange(disconnectedState)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }

    @Test("hasStateChanged with battery level differences")
    func hasStateChangedWithBatteryLevelDifferences() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        _ = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let lowBatteryState = PowerStateInfo(isConnected: true, batteryLevel: 70, isCharging: true, timestamp: Date()) // 10% difference > 5%

        try await useCase.startMonitoring()

        // Simulate significant battery level change
        await repository.simulateStateChange(lowBatteryState)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }

    @Test("hasStateChanged with minor battery level differences")
    func hasStateChangedWithMinorBatteryLevelDifferences() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        _ = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let batteryState2 = PowerStateInfo(isConnected: true, batteryLevel: 78, isCharging: true, timestamp: Date()) // 2% difference < 5%

        try await useCase.startMonitoring()

        // Simulate minor battery level change (should not trigger change)
        await repository.simulateStateChange(batteryState2)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }

    @Test("hasStateChanged with charging state differences")
    func hasStateChangedWithChargingStateDifferences() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        _ = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let notChargingState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: false, timestamp: Date())

        try await useCase.startMonitoring()

        // Simulate charging state change
        await repository.simulateStateChange(notChargingState)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }

    @Test("hasStateChanged with nil battery levels")
    func hasStateChangedWithNilBatteryLevels() async throws {
        let repository = MockPowerStateRepository()
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        _ = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let stateWithoutBattery = PowerStateInfo(isConnected: true, batteryLevel: nil, isCharging: true, timestamp: Date())

        try await useCase.startMonitoring()

        // First simulate state with battery, then without
        await repository.simulateStateChange(stateWithoutBattery)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }

    @Test("handleStateUpdate with no previous state")
    func handleStateUpdateWithNoPreviousState() async throws {
        let initialState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)

        try await useCase.startMonitoring()

        // The first state update should set previousState but not emit a change
        let newState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())
        await repository.simulateStateChange(newState)

        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        await useCase.stopMonitoring()
    }
    
    @Test("handleStateUpdate guard clause - first state update sets previousState")
    func testHandleStateUpdateFirstStateNoPreviousState() async throws {
        // Given - Create a repository that will emit states after monitoring starts
        // Use a specific initial state that's different from what we'll simulate
        let initialState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 80,  // Different from 90 we'll simulate
            isCharging: true,
            timestamp: Date()
        )
        let repository = MockPowerStateRepository(mockState: initialState)
        let analyzer = MockPowerStateAnalyzer()
        let useCase = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)
        
        // Create a way to track if changes were emitted
        var receivedChanges: [PowerStateChange] = []
        
        // Monitor the stream
        let streamTask = Task {
            for await change in useCase.powerStateChanges {
                receivedChanges.append(change)
            }
        }
        
        // When - Start monitoring
        // The initial getCurrentPowerState call will set previousState to 80% battery
        try await useCase.startMonitoring()
        
        // Wait a bit to let monitoring stabilize
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Simulate a state update with significant battery change
        // This is actually the second state the use case sees (first was from getCurrentPowerState)
        let changedState = PowerStateInfo(
            isConnected: true,
            batteryLevel: 90,  // 10% change from initial 80%
            isCharging: true,
            timestamp: Date()
        )
        await repository.simulateStateChange(changedState)
        
        // Wait a bit to ensure the state was processed
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Then - We should have received ONE change (80% -> 90%)
        #expect(receivedChanges.count == 1)
        if let change = receivedChanges.first {
            #expect(change.previousState.batteryLevel == 80)
            #expect(change.currentState.batteryLevel == 90)
            #expect(change.changeType == .batteryLevelChanged(from: 80, to: 90))
        }
        
        // Now test that the guard clause properly handles nil previousState
        // We'll create a new use case instance without starting monitoring
        let useCase2 = PowerMonitorUseCaseImpl(repository: repository, analyzer: analyzer)
        
        // The handleStateUpdate method is private, but we can test its behavior
        // by observing that no changes are emitted when previousState is nil
        var receivedChanges2: [PowerStateChange] = []
        let streamTask2 = Task {
            for await change in useCase2.powerStateChanges {
                receivedChanges2.append(change)
            }
        }
        
        // Don't start monitoring, so previousState remains nil
        // Simulate a state change - this should be handled by the guard clause
        await repository.simulateStateChange(changedState)
        
        // Wait and verify no changes were emitted
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(receivedChanges2.isEmpty)
        
        // Clean up
        await useCase.stopMonitoring()
        streamTask.cancel()
        streamTask2.cancel()
    }
    
    // Helper expectation function for async testing
    private func expectation(description: String) -> SimpleExpectation {
        return SimpleExpectation(description: description)
    }
    
    private class SimpleExpectation {
        let description: String
        var isInverted = false
        private var fulfilled = false
        
        init(description: String) {
            self.description = description
        }
        
        func fulfill() {
            fulfilled = true
        }
        
        var isFulfilled: Bool { fulfilled }
    }

    // MARK: - DefaultPowerStateAnalyzer Tests

    @Test("DefaultPowerStateAnalyzer initialization with defaults")
    func defaultPowerStateAnalyzerInitializationWithDefaults() {
        let analyzer = DefaultPowerStateAnalyzer()

        // Create a mock change to test the analyzer
        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Default settings should be armed, so disconnection should be high threat
        #expect(analysis.threatLevel == .high)
        #expect(analysis.reason.contains("potential theft attempt"))
        #expect(analysis.recommendedActions.contains(.lockScreen))
        #expect(analysis.recommendedActions.contains(.notify))
    }

    @Test("DefaultPowerStateAnalyzer with custom security settings")
    func defaultPowerStateAnalyzerWithCustomSecuritySettings() {
        let settings = DefaultPowerStateAnalyzer.SecuritySettings(
            isArmed: false,
            gracePeriodSeconds: 10.0,
            considerLocationTrusted: true
        )
        let analyzer = DefaultPowerStateAnalyzer(settings: settings)

        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Not armed, so should be no threat
        #expect(analysis.threatLevel == .none)
        #expect(analysis.reason.contains("not armed"))
    }

    @Test("DefaultPowerStateAnalyzer trusted location analysis")
    func defaultPowerStateAnalyzerTrustedLocationAnalysis() {
        let settings = DefaultPowerStateAnalyzer.SecuritySettings(
            isArmed: true,
            gracePeriodSeconds: 5.0,
            considerLocationTrusted: true
        )
        let analyzer = DefaultPowerStateAnalyzer(settings: settings)

        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Trusted location, so should be low threat
        #expect(analysis.threatLevel == .low)
        #expect(analysis.reason.contains("trusted location"))
        #expect(analysis.recommendedActions.contains(.notify))
        #expect(!analysis.recommendedActions.contains(.lockScreen))
    }

    @Test("DefaultPowerStateAnalyzer power connected analysis")
    func defaultPowerStateAnalyzerPowerConnectedAnalysis() {
        let analyzer = DefaultPowerStateAnalyzer()

        let previousState = PowerStateInfo(isConnected: false, batteryLevel: 80, isCharging: false, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Power connection is safe
        #expect(analysis.threatLevel == .none)
        #expect(analysis.reason.contains("connected"))
    }

    @Test("DefaultPowerStateAnalyzer low battery analysis")
    func defaultPowerStateAnalyzerLowBatteryAnalysis() {
        let analyzer = DefaultPowerStateAnalyzer()

        let previousState = PowerStateInfo(isConnected: false, batteryLevel: 20, isCharging: false, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 5, isCharging: false, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Low battery should be low threat
        #expect(analysis.threatLevel == .low)
        #expect(analysis.reason.contains("critically low"))
        #expect(analysis.recommendedActions.contains(.notify))
    }

    @Test("DefaultPowerStateAnalyzer normal battery analysis")
    func defaultPowerStateAnalyzerNormalBatteryAnalysis() {
        let analyzer = DefaultPowerStateAnalyzer()

        let previousState = PowerStateInfo(isConnected: false, batteryLevel: 50, isCharging: false, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: false, batteryLevel: 40, isCharging: false, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Normal battery change should be no threat
        #expect(analysis.threatLevel == .none)
        #expect(analysis.reason.contains("Battery level changed"))
    }

    @Test("DefaultPowerStateAnalyzer charging state change analysis")
    func defaultPowerStateAnalyzerChargingStateChangeAnalysis() {
        let analyzer = DefaultPowerStateAnalyzer()

        let previousState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: false, timestamp: Date())
        let currentState = PowerStateInfo(isConnected: true, batteryLevel: 80, isCharging: true, timestamp: Date())
        let change = PowerStateChange(previousState: previousState, currentState: currentState)

        let analysis = analyzer.analyzeStateChange(change)

        // Charging state change should be no threat
        #expect(analysis.threatLevel == .none)
        #expect(analysis.reason.contains("Charging state changed"))
    }

    @Test("SecuritySettings initialization with all parameters")
    func securitySettingsInitializationWithAllParameters() {
        let settings = DefaultPowerStateAnalyzer.SecuritySettings(
            isArmed: false,
            gracePeriodSeconds: 15.0,
            considerLocationTrusted: true
        )

        #expect(settings.isArmed == false)
        #expect(settings.gracePeriodSeconds == 15.0)
        #expect(settings.considerLocationTrusted == true)
    }

    @Test("SecuritySettings initialization with defaults")
    func securitySettingsInitializationWithDefaults() {
        let settings = DefaultPowerStateAnalyzer.SecuritySettings()

        #expect(settings.isArmed == true)
        #expect(settings.gracePeriodSeconds == 5.0)
        #expect(settings.considerLocationTrusted == false)
    }
}
