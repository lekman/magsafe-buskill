//
//  AutoArmUseCaseImpl.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation

/// Concrete implementation of AutoArmDecisionUseCase
public actor AutoArmDecisionUseCaseImpl: AutoArmDecisionUseCase {

    // MARK: - Properties

    private let armingService: SystemArmingService
    private let configurationStore: AutoArmConfigurationStore
    private var lastArmTime: Date?
    private var temporaryDisableUntil: Date?

    // MARK: - Initialization

    /// Initializes the auto-arm decision use case
    /// - Parameters:
    ///   - armingService: Service for system arming operations
    ///   - configurationStore: Storage for auto-arm configuration
    public init(
        armingService: SystemArmingService,
        configurationStore: AutoArmConfigurationStore = InMemoryAutoArmConfigurationStore()
    ) {
        self.armingService = armingService
        self.configurationStore = configurationStore
    }

    // MARK: - AutoArmDecisionUseCase Implementation

    /// Evaluates whether to auto-arm based on the event
    public func evaluateAutoArmEvent(_ event: AutoArmEvent) async -> AutoArmDecision {
        // Check if auto-arm is enabled
        guard event.configuration.isEnabled else {
            return .skip(reason: .disabled)
        }

        // Check if temporarily disabled
        if let disableUntil = temporaryDisableUntil, Date() < disableUntil {
            return .skip(reason: .temporarilyDisabled(until: disableUntil))
        }

        // Check if already armed
        if await armingService.isArmed() {
            return .skip(reason: .alreadyArmed)
        }

        // Check cooldown period
        if let lastArm = lastArmTime {
            let cooldownEnd = lastArm.addingTimeInterval(event.configuration.armCooldownPeriod)
            if Date() < cooldownEnd {
                return .skip(reason: .cooldownPeriod(until: cooldownEnd))
            }
        }

        // Evaluate trigger conditions
        let shouldArm = evaluateTrigger(event.trigger, configuration: event.configuration)

        if shouldArm {
            lastArmTime = Date()
            return .arm(reason: event.trigger.description)
        } else {
            return .skip(reason: .conditionNotMet)
        }
    }

    /// Checks if auto-arm is currently possible
    public func canAutoArm() async -> Bool {
        let configuration = await configurationStore.loadConfiguration() ?? .default

        // Check basic conditions
        guard configuration.isEnabled else { return false }

        if let disableUntil = temporaryDisableUntil, Date() < disableUntil {
            return false
        }

        if await armingService.isArmed() {
            return false
        }

        return true
    }

    /// Gets the current auto-arm status
    public func getAutoArmStatus() async -> AutoArmStatus {
        let configuration = await configurationStore.loadConfiguration() ?? .default
        let isArmed = await armingService.isArmed()

        return AutoArmStatus(
            isEnabled: configuration.isEnabled,
            isMonitoring: configuration.isEnabled && (configuration.armByLocation || configuration.armOnUntrustedNetwork),
            isTemporarilyDisabled: temporaryDisableUntil != nil && Date() < temporaryDisableUntil!,
            temporaryDisableUntil: temporaryDisableUntil,
            lastEvent: nil, // Would need event tracking
            currentConditions: AutoArmConditions(
                isInTrustedLocation: true, // Would need location service
                currentNetwork: NetworkInfo(isConnected: true),
                shouldAutoArm: !isArmed
            )
        )
    }

    // MARK: - Internal Methods

    func setTemporaryDisable(until date: Date?) {
        temporaryDisableUntil = date
    }

    // MARK: - Private Methods

    private func evaluateTrigger(_ trigger: AutoArmTrigger, configuration: AutoArmConfiguration) -> Bool {
        switch trigger {
        case .leftTrustedLocation:
            return configuration.armByLocation

        case .enteredUntrustedNetwork, .disconnectedFromTrustedNetwork, .lostNetworkConnectivity:
            return configuration.armOnUntrustedNetwork

        case .manual:
            return true // Manual triggers always proceed if other conditions are met
        }
    }
}

/// Concrete implementation of AutoArmConfigurationUseCase
public actor AutoArmConfigurationUseCaseImpl: AutoArmConfigurationUseCase {

    // MARK: - Properties

    private let configurationStore: AutoArmConfigurationStore
    private let decisionUseCase: AutoArmDecisionUseCaseImpl

    // MARK: - Initialization

    /// Initializes the auto-arm configuration use case
    /// - Parameters:
    ///   - configurationStore: Storage for configuration
    ///   - decisionUseCase: Use case for auto-arm decisions
    public init(
        configurationStore: AutoArmConfigurationStore = InMemoryAutoArmConfigurationStore(),
        decisionUseCase: AutoArmDecisionUseCaseImpl
    ) {
        self.configurationStore = configurationStore
        self.decisionUseCase = decisionUseCase
    }

    // MARK: - AutoArmConfigurationUseCase Implementation

    /// Gets the current auto-arm configuration
    public func getConfiguration() async -> AutoArmConfiguration {
        return await configurationStore.loadConfiguration() ?? .default
    }

    /// Updates the auto-arm configuration
    public func updateConfiguration(_ configuration: AutoArmConfiguration) async throws {
        try await configurationStore.saveConfiguration(configuration)
    }

    /// Temporarily disables auto-arm for the specified duration
    public func temporarilyDisable(for duration: TimeInterval) async {
        let until = Date().addingTimeInterval(duration)
        await decisionUseCase.setTemporaryDisable(until: until)
    }

    /// Cancels the temporary disable
    public func cancelTemporaryDisable() async {
        await decisionUseCase.setTemporaryDisable(until: nil)
    }

    /// Checks if auto-arm is temporarily disabled
    public func isTemporarilyDisabled() async -> (disabled: Bool, until: Date?) {
        let status = await decisionUseCase.getAutoArmStatus()
        return (status.isTemporarilyDisabled, status.temporaryDisableUntil)
    }
}

/// Concrete implementation of AutoArmMonitoringUseCase
public actor AutoArmMonitoringUseCaseImpl: AutoArmMonitoringUseCase {

    // MARK: - Properties

    private let locationRepository: LocationRepository
    private let networkRepository: NetworkRepository
    private let configurationStore: AutoArmConfigurationStore
    private let eventStream = AsyncStream<AutoArmEvent>.makeStream()
    private var monitoringTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Initializes the auto-arm monitoring use case
    /// - Parameters:
    ///   - locationRepository: Repository for location monitoring
    ///   - networkRepository: Repository for network monitoring
    ///   - configurationStore: Storage for configuration
    public init(
        locationRepository: LocationRepository,
        networkRepository: NetworkRepository,
        configurationStore: AutoArmConfigurationStore = InMemoryAutoArmConfigurationStore()
    ) {
        self.locationRepository = locationRepository
        self.networkRepository = networkRepository
        self.configurationStore = configurationStore
    }

    // MARK: - AutoArmMonitoringUseCase Implementation

    /// Starts monitoring for auto-arm conditions
    public func startMonitoring() async throws {
        // Stop any existing monitoring
        monitoringTask?.cancel()

        let configuration = await configurationStore.loadConfiguration() ?? .default
        guard configuration.isEnabled else { return }

        // Start repositories based on configuration
        if configuration.armByLocation {
            try await locationRepository.startMonitoring()
        }

        if configuration.armOnUntrustedNetwork {
            try await networkRepository.startMonitoring()
        }

        // Start monitoring task
        monitoringTask = Task {
            await withTaskGroup(of: Void.self) { group in
                // Monitor location changes
                if configuration.armByLocation {
                    group.addTask { [weak self] in
                        await self?.monitorLocationChanges()
                    }
                }

                // Monitor network changes
                if configuration.armOnUntrustedNetwork {
                    group.addTask { [weak self] in
                        await self?.monitorNetworkChanges()
                    }
                }
            }
        }
    }

    /// Stops monitoring
    public func stopMonitoring() async {
        monitoringTask?.cancel()
        monitoringTask = nil

        await locationRepository.stopMonitoring()
        await networkRepository.stopMonitoring()

        eventStream.continuation.finish()
    }

    /// Returns a stream of auto-arm events
    public func observeAutoArmEvents() -> AsyncStream<AutoArmEvent> {
        return eventStream.stream
    }

    // MARK: - Private Methods

    private func monitorLocationChanges() async {
        var wasInTrustedLocation = await locationRepository.isInTrustedLocation()

        for await isInTrusted in locationRepository.observeLocationTrustChanges() {
            if wasInTrustedLocation && !isInTrusted {
                // Left trusted location
                let configuration = await configurationStore.loadConfiguration() ?? .default
                let event = AutoArmEvent(
                    trigger: .leftTrustedLocation(name: nil),
                    configuration: configuration
                )
                eventStream.continuation.yield(event)
            }
            wasInTrustedLocation = isInTrusted
        }
    }

    private func monitorNetworkChanges() async {
        for await change in networkRepository.observeNetworkChanges() {
            let configuration = await configurationStore.loadConfiguration() ?? .default

            switch change {
            case .connectedToNetwork(let ssid, let trusted):
                if !trusted {
                    let event = AutoArmEvent(
                        trigger: .enteredUntrustedNetwork(ssid: ssid),
                        configuration: configuration
                    )
                    eventStream.continuation.yield(event)
                }

            case .disconnectedFromNetwork(let ssid, let trusted):
                if trusted, let ssid = ssid {
                    let event = AutoArmEvent(
                        trigger: .disconnectedFromTrustedNetwork(ssid: ssid),
                        configuration: configuration
                    )
                    eventStream.continuation.yield(event)
                }

            case .connectivityChanged(let isConnected):
                if !isConnected {
                    let event = AutoArmEvent(
                        trigger: .lostNetworkConnectivity,
                        configuration: configuration
                    )
                    eventStream.continuation.yield(event)
                }
            }
        }
    }
}

// MARK: - Configuration Storage

/// Protocol for persisting auto-arm configuration
public protocol AutoArmConfigurationStore {
    /// Saves auto-arm configuration to persistent storage
    func saveConfiguration(_ configuration: AutoArmConfiguration) async throws
    /// Loads auto-arm configuration from persistent storage
    func loadConfiguration() async -> AutoArmConfiguration?
}

/// In-memory implementation of configuration store
public actor InMemoryAutoArmConfigurationStore: AutoArmConfigurationStore {
    private var storedConfiguration: AutoArmConfiguration?

    /// Initializes the in-memory configuration store
    public init() {}

    /// Saves configuration to memory
    public func saveConfiguration(_ configuration: AutoArmConfiguration) async throws {
        storedConfiguration = configuration
    }

    /// Loads configuration from memory
    public func loadConfiguration() async -> AutoArmConfiguration? {
        return storedConfiguration
    }
}
