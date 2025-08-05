//
//  AutoArmUseCaseImplTests.swift
//  MagSafe Guard
//
//  Created on 2025-08-04.
//
//  Tests for AutoArmUseCaseImpl to achieve 95%+ coverage

import Foundation
@testable import MagSafeGuardDomain
import Testing

@Suite("AutoArmUseCaseImpl Tests")
struct AutoArmUseCaseImplTests {

    // MARK: - Mock Dependencies

    private actor MockSystemArmingService: SystemArmingService {
        private var armed: Bool = false
        private var shouldFailArm: Bool = false

        init(armed: Bool = false, shouldFailArm: Bool = false) {
            self.armed = armed
            self.shouldFailArm = shouldFailArm
        }

        func isArmed() async -> Bool {
            return armed
        }

        func arm() async throws {
            if shouldFailArm {
                throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock arm failed"])
            }
            armed = true
        }

        // Test helpers
        func setArmed(_ value: Bool) {
            armed = value
        }
    }

    private actor MockLocationRepository: LocationRepository {
        private var monitoring = false
        private var inTrustedLocation = false
        private var trustedLocations: [TrustedLocationDomain] = []
        nonisolated let trustChangeStream = AsyncStream<Bool>.makeStream()
        private var shouldFailStart = false

        init(inTrustedLocation: Bool = false, shouldFailStart: Bool = false) {
            self.inTrustedLocation = inTrustedLocation
            self.shouldFailStart = shouldFailStart
        }

        func startMonitoring() async throws {
            if shouldFailStart {
                throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock start failed"])
            }
            monitoring = true
        }

        func stopMonitoring() async {
            monitoring = false
            trustChangeStream.continuation.finish()
        }

        func isInTrustedLocation() async -> Bool {
            return inTrustedLocation
        }

        func addTrustedLocation(_ location: TrustedLocationDomain) async throws {
            trustedLocations.append(location)
        }

        func removeTrustedLocation(id: UUID) async throws {
            trustedLocations.removeAll { $0.id == id }
        }

        func getTrustedLocations() async -> [TrustedLocationDomain] {
            return trustedLocations
        }

        nonisolated func observeLocationTrustChanges() -> AsyncStream<Bool> {
            return trustChangeStream.stream
        }

        // Test helpers
        func setInTrustedLocation(_ value: Bool) {
            inTrustedLocation = value
        }

        func emitTrustChange(_ trusted: Bool) {
            trustChangeStream.continuation.yield(trusted)
        }
    }

    private actor MockNetworkRepository: NetworkRepository {
        private var monitoring = false
        private var currentNetwork = NetworkInfo(isConnected: false)
        private var trustedNetworks: [TrustedNetwork] = []
        nonisolated let networkChangeStream = AsyncStream<NetworkChangeEvent>.makeStream()
        private var shouldFailStart = false

        init(currentNetwork: NetworkInfo = NetworkInfo(isConnected: false), shouldFailStart: Bool = false) {
            self.currentNetwork = currentNetwork
            self.shouldFailStart = shouldFailStart
        }

        func startMonitoring() async throws {
            if shouldFailStart {
                throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock start failed"])
            }
            monitoring = true
        }

        func stopMonitoring() async {
            monitoring = false
            networkChangeStream.continuation.finish()
        }

        func getCurrentNetworkInfo() async -> NetworkInfo {
            return currentNetwork
        }

        func addTrustedNetwork(_ network: TrustedNetwork) async throws {
            trustedNetworks.append(network)
        }

        func removeTrustedNetwork(ssid: String) async throws {
            trustedNetworks.removeAll { $0.ssid == ssid }
        }

        func getTrustedNetworks() async -> [TrustedNetwork] {
            return trustedNetworks
        }

        nonisolated func observeNetworkChanges() -> AsyncStream<NetworkChangeEvent> {
            return networkChangeStream.stream
        }

        // Test helpers
        func emitNetworkChange(_ event: NetworkChangeEvent) {
            networkChangeStream.continuation.yield(event)
        }
    }

    // MARK: - AutoArmDecisionUseCaseImpl Tests

    @Test("AutoArmDecisionUseCaseImpl initialization")
    func autoArmDecisionUseCaseImplInitialization() async {
        let armingService = MockSystemArmingService()
        let configStore = InMemoryAutoArmConfigurationStore()

        // Save enabled configuration
        let config = AutoArmConfiguration(isEnabled: true)
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        // Test that initialization doesn't fail
        #expect(await useCase.canAutoArm() == true)
    }

    @Test("AutoArmDecisionUseCaseImpl initialization with defaults")
    func initializationWithDefaults() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        #expect(await useCase.canAutoArm() == false) // Default config has isEnabled = false
    }

    @Test("Evaluate auto-arm event - disabled")
    func evaluateAutoArmEventDisabled() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: .defaultConfig // isEnabled = false
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .skip(let reason) = decision else {
            #expect(Bool(false), "Should skip when disabled")
            return
        }

        if case .disabled = reason {
            // Expected
        } else {
            #expect(Bool(false), "Should skip due to disabled")
        }
    }

    @Test("Evaluate auto-arm event - temporarily disabled")
    func evaluateAutoArmEventTemporarilyDisabled() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        // Set temporary disable
        await useCase.setTemporaryDisable(until: Date().addingTimeInterval(3600))

        let config = AutoArmConfiguration(isEnabled: true, armByLocation: true)
        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .skip(let reason) = decision else {
            #expect(Bool(false), "Should skip when temporarily disabled")
            return
        }

        if case .temporarilyDisabled = reason {
            // Expected
        } else {
            #expect(Bool(false), "Should skip due to temporary disable")
        }
    }

    @Test("Evaluate auto-arm event - already armed")
    func evaluateAutoArmEventAlreadyArmed() async {
        let armingService = MockSystemArmingService(armed: true)
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(isEnabled: true, armByLocation: true)
        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .skip(let reason) = decision else {
            #expect(Bool(false), "Should skip when already armed")
            return
        }

        if case .alreadyArmed = reason {
            // Expected
        } else {
            #expect(Bool(false), "Should skip due to already armed")
        }
    }

    @Test("Evaluate auto-arm event - cooldown period")
    func evaluateAutoArmEventCooldownPeriod() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armCooldownPeriod: 300 // 5 minutes
        )

        // First event - should arm
        let event1 = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision1 = await useCase.evaluateAutoArmEvent(event1)
        #expect(decision1.shouldArm)

        // Second event immediately after - should be in cooldown
        let event2 = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Office"),
            configuration: config
        )

        let decision2 = await useCase.evaluateAutoArmEvent(event2)

        guard case .skip(let reason) = decision2 else {
            #expect(Bool(false), "Should skip due to cooldown")
            return
        }

        if case .cooldownPeriod = reason {
            // Expected
        } else {
            #expect(Bool(false), "Should skip due to cooldown period")
        }
    }

    @Test("Evaluate auto-arm event - successful arm for location trigger")
    func evaluateAutoArmEventSuccessfulLocationTrigger() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: false
        )

        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .arm(let reason) = decision else {
            #expect(Bool(false), "Should decide to arm")
            return
        }

        #expect(reason == "Left trusted location: Home")
    }

    @Test("Evaluate auto-arm event - successful arm for network trigger")
    func evaluateAutoArmEventSuccessfulNetworkTrigger() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: false,
            armOnUntrustedNetwork: true
        )

        let event = AutoArmEvent(
            trigger: .enteredUntrustedNetwork(ssid: "PublicWiFi"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .arm(let reason) = decision else {
            #expect(Bool(false), "Should decide to arm")
            return
        }

        #expect(reason == "Connected to untrusted network: PublicWiFi")
    }

    @Test("Evaluate auto-arm event - condition not met")
    func evaluateAutoArmEventConditionNotMet() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: false, // Location trigger disabled
            armOnUntrustedNetwork: false // Network trigger disabled
        )

        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .skip(let reason) = decision else {
            #expect(Bool(false), "Should skip when condition not met")
            return
        }

        if case .conditionNotMet = reason {
            // Expected
        } else {
            #expect(Bool(false), "Should skip due to condition not met")
        }
    }

    @Test("Evaluate auto-arm event - manual trigger always proceeds")
    func evaluateAutoArmEventManualTrigger() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: false,
            armOnUntrustedNetwork: false
        )

        let event = AutoArmEvent(
            trigger: .manual(reason: "User requested"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        guard case .arm(let reason) = decision else {
            #expect(Bool(false), "Manual trigger should arm")
            return
        }

        #expect(reason == "User requested")
    }

    @Test("Can auto-arm - all conditions met")
    func canAutoArmAllConditionsMet() async {
        let armingService = MockSystemArmingService(armed: false)
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: true)
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let canArm = await useCase.canAutoArm()
        #expect(canArm == true)
    }

    @Test("Can auto-arm - disabled")
    func canAutoArmDisabled() async {
        let armingService = MockSystemArmingService()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: false)
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let canArm = await useCase.canAutoArm()
        #expect(canArm == false)
    }

    @Test("Can auto-arm - temporarily disabled")
    func canAutoArmTemporarilyDisabled() async {
        let armingService = MockSystemArmingService()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: true)
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        await useCase.setTemporaryDisable(until: Date().addingTimeInterval(3600))

        let canArm = await useCase.canAutoArm()
        #expect(canArm == false)
    }

    @Test("Can auto-arm - already armed")
    func canAutoArmAlreadyArmed() async {
        let armingService = MockSystemArmingService(armed: true)
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: true)
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let canArm = await useCase.canAutoArm()
        #expect(canArm == false)
    }

    @Test("Get auto-arm status")
    func getAutoArmStatus() async {
        let armingService = MockSystemArmingService(armed: false)
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: true
        )
        try? await configStore.saveConfiguration(config)

        let useCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let status = await useCase.getAutoArmStatus()

        #expect(status.isEnabled == true)
        #expect(status.isMonitoring == true)
        #expect(status.isTemporarilyDisabled == false)
        #expect(status.temporaryDisableUntil == nil)
        #expect(status.currentConditions.shouldAutoArm == true)
    }

    @Test("Get auto-arm status with temporary disable")
    func getAutoArmStatusWithTemporaryDisable() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let disableUntil = Date().addingTimeInterval(3600)
        await useCase.setTemporaryDisable(until: disableUntil)

        let status = await useCase.getAutoArmStatus()

        #expect(status.isTemporarilyDisabled == true)
        #expect(status.temporaryDisableUntil == disableUntil)
    }

    @Test("Set and clear temporary disable")
    func setAndClearTemporaryDisable() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        // Set temporary disable
        let disableUntil = Date().addingTimeInterval(3600)
        await useCase.setTemporaryDisable(until: disableUntil)

        var status = await useCase.getAutoArmStatus()
        #expect(status.isTemporarilyDisabled == true)

        // Clear temporary disable
        await useCase.setTemporaryDisable(until: nil)

        status = await useCase.getAutoArmStatus()
        #expect(status.isTemporarilyDisabled == false)
        #expect(status.temporaryDisableUntil == nil)
    }

    @Test("Evaluate network triggers - disconnected from trusted")
    func evaluateNetworkTriggerDisconnectedFromTrusted() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )

        let event = AutoArmEvent(
            trigger: .disconnectedFromTrustedNetwork(ssid: "HomeWiFi"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)
        #expect(decision.shouldArm)
    }

    @Test("Evaluate network triggers - lost connectivity")
    func evaluateNetworkTriggerLostConnectivity() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )

        let event = AutoArmEvent(
            trigger: .lostNetworkConnectivity,
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)
        #expect(decision.shouldArm)
    }

    // MARK: - AutoArmConfigurationUseCaseImpl Tests

    @Test("AutoArmConfigurationUseCaseImpl initialization")
    func autoArmConfigurationUseCaseImplInitialization() async {
        let armingService = MockSystemArmingService()
        let decisionUseCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let useCase = AutoArmConfigurationUseCaseImpl(
            decisionUseCase: decisionUseCase
        )

        let config = await useCase.getConfiguration()
        #expect(config == .defaultConfig)
    }

    @Test("Get configuration")
    func getConfiguration() async {
        let armingService = MockSystemArmingService()
        let configStore = InMemoryAutoArmConfigurationStore()
        let customConfig = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armCooldownPeriod: 60
        )
        try? await configStore.saveConfiguration(customConfig)

        let decisionUseCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let useCase = AutoArmConfigurationUseCaseImpl(
            configurationStore: configStore,
            decisionUseCase: decisionUseCase
        )

        let config = await useCase.getConfiguration()
        #expect(config == customConfig)
    }

    @Test("Update configuration")
    func updateConfiguration() async throws {
        let armingService = MockSystemArmingService()
        let configStore = InMemoryAutoArmConfigurationStore()
        let decisionUseCase = AutoArmDecisionUseCaseImpl(
            armingService: armingService,
            configurationStore: configStore
        )

        let useCase = AutoArmConfigurationUseCaseImpl(
            configurationStore: configStore,
            decisionUseCase: decisionUseCase
        )

        let newConfig = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: true,
            armCooldownPeriod: 120
        )

        try await useCase.updateConfiguration(newConfig)

        let retrievedConfig = await useCase.getConfiguration()
        #expect(retrievedConfig == newConfig)
    }

    @Test("Temporarily disable auto-arm")
    func temporarilyDisableAutoArm() async {
        let armingService = MockSystemArmingService()
        let decisionUseCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let useCase = AutoArmConfigurationUseCaseImpl(
            decisionUseCase: decisionUseCase
        )

        await useCase.temporarilyDisable(for: 3600) // 1 hour

        let (disabled, until) = await useCase.isTemporarilyDisabled()
        #expect(disabled == true)
        #expect(until != nil)
    }

    @Test("Cancel temporary disable")
    func cancelTemporaryDisable() async {
        let armingService = MockSystemArmingService()
        let decisionUseCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let useCase = AutoArmConfigurationUseCaseImpl(
            decisionUseCase: decisionUseCase
        )

        // First disable
        await useCase.temporarilyDisable(for: 3600)

        var (disabled, _) = await useCase.isTemporarilyDisabled()
        #expect(disabled == true)

        // Then cancel
        await useCase.cancelTemporaryDisable()

        (disabled, _) = await useCase.isTemporarilyDisabled()
        #expect(disabled == false)
    }

    @Test("Is temporarily disabled")
    func isTemporarilyDisabled() async {
        let armingService = MockSystemArmingService()
        let decisionUseCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        let useCase = AutoArmConfigurationUseCaseImpl(
            decisionUseCase: decisionUseCase
        )

        // Initially not disabled
        var (disabled, until) = await useCase.isTemporarilyDisabled()
        #expect(disabled == false)
        #expect(until == nil)

        // Disable for 1 hour
        await useCase.temporarilyDisable(for: 3600)

        (disabled, until) = await useCase.isTemporarilyDisabled()
        #expect(disabled == true)
        #expect(until != nil)

        if let untilDate = until {
            let timeDiff = untilDate.timeIntervalSince(Date())
            #expect(timeDiff > 3500 && timeDiff < 3700) // Close to 1 hour
        }
    }

    // MARK: - AutoArmMonitoringUseCaseImpl Tests

    @Test("AutoArmMonitoringUseCaseImpl initialization")
    func autoArmMonitoringUseCaseImplInitialization() async {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo
        )

        // Test that initialization doesn't fail
        _ = useCase.observeAutoArmEvents()
    }

    @Test("Start monitoring - disabled")
    func startMonitoringDisabled() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        // Save disabled configuration
        let config = AutoArmConfiguration(isEnabled: false)
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Should not throw when disabled
        try await useCase.startMonitoring()
    }

    @Test("Start monitoring - location only")
    func startMonitoringLocationOnly() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: false
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        try await useCase.startMonitoring()

        // Give time for monitoring to start
        try await Task.sleep(nanoseconds: 10_000_000)

        await useCase.stopMonitoring()
    }

    @Test("Start monitoring - network only")
    func startMonitoringNetworkOnly() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: false,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        try await useCase.startMonitoring()

        // Give time for monitoring to start
        try await Task.sleep(nanoseconds: 10_000_000)

        await useCase.stopMonitoring()
    }

    @Test("Start monitoring - both location and network")
    func startMonitoringBothLocationAndNetwork() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        try await useCase.startMonitoring()

        // Give time for monitoring to start
        try await Task.sleep(nanoseconds: 10_000_000)

        await useCase.stopMonitoring()
    }

    @Test("Stop monitoring")
    func stopMonitoring() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: true, armByLocation: true)
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        try await useCase.startMonitoring()

        // Stop should not throw
        await useCase.stopMonitoring()
    }

    @Test("Multiple start monitoring calls")
    func multipleStartMonitoringCalls() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(isEnabled: true, armByLocation: true)
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // First start
        try await useCase.startMonitoring()

        // Second start should cancel first
        try await useCase.startMonitoring()

        await useCase.stopMonitoring()
    }

    @Test("Monitor location changes - left trusted location")
    func monitorLocationChangesLeftTrusted() async throws {
        let locationRepo = MockLocationRepository(inTrustedLocation: true)
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate leaving trusted location
        await locationRepo.emitTrustChange(false)

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 1)
        if let event = events.first {
            if case .leftTrustedLocation = event.trigger {
                // Expected
            } else {
                #expect(Bool(false), "Should have left trusted location trigger")
            }
        }
    }

    @Test("Monitor network changes - entered untrusted network")
    func monitorNetworkChangesEnteredUntrusted() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate connecting to untrusted network
        await networkRepo.emitNetworkChange(.connectedToNetwork(ssid: "PublicWiFi", trusted: false))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 1)
        if let event = events.first {
            if case .enteredUntrustedNetwork(let ssid) = event.trigger {
                #expect(ssid == "PublicWiFi")
            } else {
                #expect(Bool(false), "Should have entered untrusted network trigger")
            }
        }
    }

    @Test("Monitor network changes - disconnected from trusted network")
    func monitorNetworkChangesDisconnectedFromTrusted() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate disconnecting from trusted network
        await networkRepo.emitNetworkChange(.disconnectedFromNetwork(ssid: "HomeWiFi", trusted: true))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 1)
        if let event = events.first {
            if case .disconnectedFromTrustedNetwork(let ssid) = event.trigger {
                #expect(ssid == "HomeWiFi")
            } else {
                #expect(Bool(false), "Should have disconnected from trusted network trigger")
            }
        }
    }

    @Test("Monitor network changes - lost connectivity")
    func monitorNetworkChangesLostConnectivity() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate losing connectivity
        await networkRepo.emitNetworkChange(.connectivityChanged(isConnected: false))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 1)
        if let event = events.first {
            if case .lostNetworkConnectivity = event.trigger {
                // Expected
            } else {
                #expect(Bool(false), "Should have lost connectivity trigger")
            }
        }
    }

    @Test("Monitor network changes - ignore trusted network connection")
    func monitorNetworkChangesIgnoreTrustedConnection() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate connecting to trusted network - should not trigger
        await networkRepo.emitNetworkChange(.connectedToNetwork(ssid: "HomeWiFi", trusted: true))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 0) // No events for trusted network
    }

    @Test("Monitor location changes - no event when entering trusted")
    func monitorLocationChangesNoEventWhenEnteringTrusted() async throws {
        let locationRepo = MockLocationRepository(inTrustedLocation: false)
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate entering trusted location - should not trigger
        await locationRepo.emitTrustChange(true)

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 0) // No events for entering trusted location
    }

    // MARK: - InMemoryAutoArmConfigurationStore Tests

    @Test("InMemoryAutoArmConfigurationStore save and load")
    func inMemoryConfigurationStoreSaveAndLoad() async throws {
        let store = InMemoryAutoArmConfigurationStore()

        // Initially nil
        let initial = await store.loadConfiguration()
        #expect(initial == nil)

        // Save configuration
        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armCooldownPeriod: 120
        )
        try await store.saveConfiguration(config)

        // Load saved configuration
        let loaded = await store.loadConfiguration()
        #expect(loaded == config)

        // Update configuration
        let updated = AutoArmConfiguration(
            isEnabled: false,
            armByLocation: false,
            armCooldownPeriod: 60
        )
        try await store.saveConfiguration(updated)

        // Load updated configuration
        let reloaded = await store.loadConfiguration()
        #expect(reloaded == updated)
    }

    // MARK: - Edge Cases and Integration Tests

    @Test("Configuration validation - negative cooldown period")
    func configurationValidationNegativeCooldown() {
        let config = AutoArmConfiguration(
            isEnabled: true,
            armCooldownPeriod: -100
        )

        // Should clamp to 0
        #expect(config.armCooldownPeriod == 0)
    }

    @Test("Configuration validation - negative notification delay")
    func configurationValidationNegativeNotificationDelay() {
        let config = AutoArmConfiguration(
            isEnabled: true,
            notificationDelay: -5
        )

        // Should clamp to 0
        #expect(config.notificationDelay == 0)
    }

    @Test("Auto-arm decision with expired temporary disable")
    func autoArmDecisionWithExpiredTemporaryDisable() async {
        let armingService = MockSystemArmingService()
        let useCase = AutoArmDecisionUseCaseImpl(armingService: armingService)

        // Set temporary disable that's already expired
        await useCase.setTemporaryDisable(until: Date().addingTimeInterval(-3600))

        let config = AutoArmConfiguration(isEnabled: true, armByLocation: true)
        let event = AutoArmEvent(
            trigger: .leftTrustedLocation(name: "Home"),
            configuration: config
        )

        let decision = await useCase.evaluateAutoArmEvent(event)

        // Should not be blocked by expired disable
        #expect(decision.shouldArm)
    }

    @Test("Concurrent monitoring operations")
    func concurrentMonitoringOperations() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armByLocation: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Start multiple monitoring operations concurrently
        async let start1: Void = useCase.startMonitoring()
        async let start2: Void = useCase.startMonitoring()
        async let stop1: Void = useCase.stopMonitoring()

        // Should handle concurrent operations gracefully
        _ = try await (start1, start2, stop1)

        // Final stop
        await useCase.stopMonitoring()
    }

    @Test("Monitor network changes - disconnected from network without SSID")
    func monitorNetworkChangesDisconnectedWithoutSSID() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate disconnecting from trusted network without SSID
        await networkRepo.emitNetworkChange(.disconnectedFromNetwork(ssid: nil, trusted: true))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        // Should not generate event without SSID
        #expect(events.count == 0)
    }

    @Test("Monitor network changes - ignore connectivity restored")
    func monitorNetworkChangesIgnoreConnectivityRestored() async throws {
        let locationRepo = MockLocationRepository()
        let networkRepo = MockNetworkRepository()
        let configStore = InMemoryAutoArmConfigurationStore()

        let config = AutoArmConfiguration(
            isEnabled: true,
            armOnUntrustedNetwork: true
        )
        try await configStore.saveConfiguration(config)

        let useCase = AutoArmMonitoringUseCaseImpl(
            locationRepository: locationRepo,
            networkRepository: networkRepo,
            configurationStore: configStore
        )

        // Set up event collection
        var events: [AutoArmEvent] = []
        let eventStream = useCase.observeAutoArmEvents()

        let collectTask = Task {
            for await event in eventStream {
                events.append(event)
            }
        }

        try await useCase.startMonitoring()

        // Simulate connectivity restored - should not trigger
        await networkRepo.emitNetworkChange(.connectivityChanged(isConnected: true))

        // Give time for event to be processed
        try await Task.sleep(nanoseconds: 50_000_000)

        await useCase.stopMonitoring()
        collectTask.cancel()

        #expect(events.count == 0) // No events for connectivity restored
    }
}
