//
//  SecurityActionUseCaseImpl.swift
//  MagSafe Guard
//
//  Implementation of security action use cases with pure business logic.
//  This class contains no system dependencies and is fully testable.
//

import Foundation

/// Concrete implementation of SecurityActionExecutionUseCase
public actor SecurityActionExecutionUseCaseImpl: SecurityActionExecutionUseCase {

    // MARK: - Properties

    private let repository: SecurityActionRepository
    private let configurationStore: SecurityActionConfigurationStore
    private var isCurrentlyExecuting = false

    // MARK: - Initialization

    public init(
        repository: SecurityActionRepository,
        configurationStore: SecurityActionConfigurationStore = InMemoryConfigurationStore()
    ) {
        self.repository = repository
        self.configurationStore = configurationStore
    }

    // MARK: - SecurityActionExecutionUseCase Implementation

    public func executeActions(request: SecurityActionRequest) async -> SecurityActionExecutionResult {
        // Check if already executing
        guard !isCurrentlyExecuting else {
            return SecurityActionExecutionResult(
                request: request,
                executedActions: [
                    SecurityActionResult(
                        actionType: .lockScreen,
                        success: false,
                        error: .alreadyExecuting
                    )
                ],
                startTime: Date(),
                endTime: Date()
            )
        }

        isCurrentlyExecuting = true
        defer { isCurrentlyExecuting = false }

        let startTime = Date()

        // Apply action delay if configured
        if request.configuration.actionDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(request.configuration.actionDelay * 1_000_000_000))
        }

        // Get sorted actions (screen lock first)
        let sortedActions = getSortedActions(from: request.configuration.enabledActions)

        // Choose execution strategy
        let strategy: SecurityActionExecutionStrategy = request.configuration.executeInParallel
            ? ParallelExecutionStrategy()
            : SequentialExecutionStrategy()

        // Execute actions
        let results = await strategy.executeActions(
            sortedActions,
            configuration: request.configuration,
            repository: repository
        )

        let endTime = Date()

        return SecurityActionExecutionResult(
            request: request,
            executedActions: results,
            startTime: startTime,
            endTime: endTime
        )
    }

    public func isExecuting() async -> Bool {
        return isCurrentlyExecuting
    }

    public func stopOngoingActions() async {
        await repository.stopAlarm()
    }

    // MARK: - Private Methods

    private func getSortedActions(from enabledActions: Set<SecurityActionType>) -> [SecurityActionType] {
        return enabledActions.sorted { action1, action2 in
            // Screen lock has highest priority
            if action1 == .lockScreen { return true }
            if action2 == .lockScreen { return false }
            return action1.rawValue < action2.rawValue
        }
    }
}

/// Concrete implementation of SecurityActionConfigurationUseCase
public actor SecurityActionConfigurationUseCaseImpl: SecurityActionConfigurationUseCase {

    // MARK: - Properties

    private let configurationStore: SecurityActionConfigurationStore
    private var currentConfiguration: SecurityActionConfiguration

    // MARK: - Initialization

    public init(
        configurationStore: SecurityActionConfigurationStore = InMemoryConfigurationStore()
    ) {
        self.configurationStore = configurationStore
        self.currentConfiguration = .default

        Task {
            // Load persisted configuration
            if let stored = await configurationStore.loadConfiguration() {
                self.currentConfiguration = stored
            }
        }
    }

    // MARK: - SecurityActionConfigurationUseCase Implementation

    public func getCurrentConfiguration() async -> SecurityActionConfiguration {
        return currentConfiguration
    }

    public func updateConfiguration(_ configuration: SecurityActionConfiguration) async throws {
        // Validate configuration
        let validationResult = validateConfiguration(configuration)
        if case .failure(let error) = validationResult {
            throw error
        }

        // Update and persist
        currentConfiguration = configuration
        try await configurationStore.saveConfiguration(configuration)
    }

    public func validateConfiguration(_ configuration: SecurityActionConfiguration) -> Result<Void, SecurityActionError> {
        // Validate alarm volume
        if configuration.alarmVolume < 0 || configuration.alarmVolume > 1 {
            return .failure(.invalidConfiguration(reason: "Alarm volume must be between 0 and 1"))
        }

        // Validate shutdown delay
        if configuration.shutdownDelay < 0 {
            return .failure(.invalidConfiguration(reason: "Shutdown delay cannot be negative"))
        }

        // Validate action delay
        if configuration.actionDelay < 0 {
            return .failure(.invalidConfiguration(reason: "Action delay cannot be negative"))
        }

        // Validate custom script if enabled
        if configuration.enabledActions.contains(.customScript) {
            guard let scriptPath = configuration.customScriptPath,
                  !scriptPath.isEmpty else {
                return .failure(.invalidConfiguration(reason: "Custom script path is required when custom script action is enabled"))
            }
        }

        // At least one action should be enabled
        if configuration.enabledActions.isEmpty {
            return .failure(.invalidConfiguration(reason: "At least one security action must be enabled"))
        }

        return .success(())
    }

    public func resetToDefault() async {
        currentConfiguration = .default
        try? await configurationStore.saveConfiguration(currentConfiguration)
    }
}

// MARK: - Configuration Storage

/// Protocol for persisting security action configuration
public protocol SecurityActionConfigurationStore {
    func saveConfiguration(_ configuration: SecurityActionConfiguration) async throws
    func loadConfiguration() async -> SecurityActionConfiguration?
}

/// In-memory implementation of configuration store
public actor InMemoryConfigurationStore: SecurityActionConfigurationStore {
    private var storedConfiguration: SecurityActionConfiguration?

    public init() {}

    public func saveConfiguration(_ configuration: SecurityActionConfiguration) async throws {
        storedConfiguration = configuration
    }

    public func loadConfiguration() async -> SecurityActionConfiguration? {
        return storedConfiguration
    }
}

/// UserDefaults-based configuration store
public actor UserDefaultsConfigurationStore: SecurityActionConfigurationStore {
    private let userDefaults: UserDefaults
    private let key = "SecurityActionConfiguration"

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func saveConfiguration(_ configuration: SecurityActionConfiguration) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(ConfigurationDTO(from: configuration))
        userDefaults.set(data, forKey: key)
    }

    public func loadConfiguration() async -> SecurityActionConfiguration? {
        guard let data = userDefaults.data(forKey: key) else { return nil }

        let decoder = JSONDecoder()
        guard let dto = try? decoder.decode(ConfigurationDTO.self, from: data) else { return nil }

        return dto.toDomainModel()
    }
}

// MARK: - Data Transfer Objects

/// DTO for configuration persistence
private struct ConfigurationDTO: Codable {
    let enabledActions: [String]
    let actionDelay: TimeInterval
    let alarmVolume: Float
    let shutdownDelay: TimeInterval
    let customScriptPath: String?
    let executeInParallel: Bool

    init(from configuration: SecurityActionConfiguration) {
        self.enabledActions = configuration.enabledActions.map { $0.rawValue }
        self.actionDelay = configuration.actionDelay
        self.alarmVolume = configuration.alarmVolume
        self.shutdownDelay = configuration.shutdownDelay
        self.customScriptPath = configuration.customScriptPath
        self.executeInParallel = configuration.executeInParallel
    }

    func toDomainModel() -> SecurityActionConfiguration {
        let actions = Set(enabledActions.compactMap { SecurityActionType(rawValue: $0) })
        return SecurityActionConfiguration(
            enabledActions: actions,
            actionDelay: actionDelay,
            alarmVolume: alarmVolume,
            shutdownDelay: shutdownDelay,
            customScriptPath: customScriptPath,
            executeInParallel: executeInParallel
        )
    }
}
