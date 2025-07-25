//
//  SecurityActionsService.swift
//  MagSafe Guard
//
//  Created on 2025-07-25.
//
//  This service manages and executes security actions when power is disconnected
//  while the system is armed. It provides a configurable set of actions to protect
//  the device from unauthorized access.
//

import Foundation

/// Service responsible for executing security actions when theft is detected
public class SecurityActionsService {
    
    // MARK: - Types
    
    /// Available security actions
    public enum SecurityAction: String, CaseIterable, Codable {
        case screenLock = "screen_lock"
        case soundAlarm = "sound_alarm"
        case forceLogout = "force_logout"
        case shutdown = "shutdown"
        case customScript = "custom_script"
        
        var displayName: String {
            switch self {
            case .screenLock: return "Lock Screen"
            case .soundAlarm: return "Sound Alarm"
            case .forceLogout: return "Force Logout"
            case .shutdown: return "System Shutdown"
            case .customScript: return "Custom Script"
            }
        }
        
        var description: String {
            switch self {
            case .screenLock: return "Immediately lock the screen requiring authentication"
            case .soundAlarm: return "Play a loud alarm sound to deter theft"
            case .forceLogout: return "Force logout all users and lock screen"
            case .shutdown: return "Shutdown the system after a countdown"
            case .customScript: return "Execute a custom shell script"
            }
        }
        
        var defaultEnabled: Bool {
            switch self {
            case .screenLock: return true  // Screen lock is enabled by default
            case .soundAlarm: return false
            case .forceLogout: return false
            case .shutdown: return false
            case .customScript: return false
            }
        }
    }
    
    /// Configuration for security actions
    public struct Configuration: Codable {
        var enabledActions: Set<SecurityAction>
        var actionDelay: TimeInterval // Delay before executing actions
        var alarmVolume: Float // 0.0 to 1.0
        var shutdownDelay: TimeInterval // Delay before shutdown
        var customScriptPath: String?
        var executeInParallel: Bool // Execute actions in parallel vs sequential
        
        static let defaultConfiguration = Configuration(
            enabledActions: [.screenLock],
            actionDelay: 0, // Immediate by default
            alarmVolume: 1.0,
            shutdownDelay: 30, // 30 seconds before shutdown
            customScriptPath: nil,
            executeInParallel: false
        )
    }
    
    /// Result of executing security actions
    public struct ExecutionResult {
        let executedActions: [SecurityAction]
        let failedActions: [(action: SecurityAction, error: Error)]
        let timestamp: Date
        
        var allSucceeded: Bool {
            return failedActions.isEmpty
        }
    }
    
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = SecurityActionsService()
    
    /// Current configuration
    private(set) public var configuration: Configuration
    
    /// System actions implementation
    private let systemActions: SystemActionsProtocol
    
    /// Flag to track if actions are currently executing
    private var isCurrentlyExecuting = false
    private let executingLock = NSLock()
    
    public var isExecuting: Bool {
        executingLock.lock()
        defer { executingLock.unlock() }
        return isCurrentlyExecuting
    }
    
    /// Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.magsafeguard.securityactions", qos: .userInitiated)
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = Configuration.defaultConfiguration
        self.systemActions = MacSystemActions()
        loadConfiguration()
    }
    
    /// Initialize with custom system actions (for testing)
    internal init(systemActions: SystemActionsProtocol) {
        self.configuration = Configuration.defaultConfiguration
        self.systemActions = systemActions
        loadConfiguration()
    }
    
    /// Reset configuration to default (for testing)
    internal func resetToDefault() {
        queue.sync {
            self.configuration = Configuration.defaultConfiguration
            UserDefaults.standard.removeObject(forKey: "SecurityActionsConfiguration")
        }
    }
    
    // MARK: - Public Methods
    
    /// Execute all enabled security actions
    /// - Parameter completion: Callback with execution result
    public func executeActions(completion: @escaping (ExecutionResult) -> Void) {
        guard trySetExecuting() else {
            print("[SecurityActionsService] Actions already executing, ignoring request")
            return
        }
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.performExecution(completion: completion)
        }
    }
    
    // MARK: - Execution Helper Methods
    
    /// Try to set the executing flag atomically
    /// - Returns: true if successfully set, false if already executing
    private func trySetExecuting() -> Bool {
        executingLock.lock()
        defer { executingLock.unlock() }
        
        if isCurrentlyExecuting {
            return false
        }
        isCurrentlyExecuting = true
        return true
    }
    
    /// Clear the executing flag
    private func clearExecuting() {
        executingLock.lock()
        defer { executingLock.unlock() }
        isCurrentlyExecuting = false
    }
    
    /// Perform the actual execution of actions
    private func performExecution(completion: @escaping (ExecutionResult) -> Void) {
        let startTime = Date()
        
        // Apply configured delay
        applyActionDelay()
        
        // Execute actions and collect results
        let (executedActions, failedActions) = executeEnabledActions()
        
        // Clear executing flag and create result
        clearExecuting()
        
        let result = ExecutionResult(
            executedActions: executedActions,
            failedActions: failedActions,
            timestamp: startTime
        )
        
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    /// Apply configured delay before executing actions
    private func applyActionDelay() {
        if configuration.actionDelay > 0 {
            print("[SecurityActionsService] Waiting \(configuration.actionDelay)s before executing actions")
            Thread.sleep(forTimeInterval: configuration.actionDelay)
        }
    }
    
    /// Execute all enabled actions and return results
    /// - Returns: Tuple of (executed actions, failed actions with errors)
    private func executeEnabledActions() -> ([SecurityAction], [(SecurityAction, Error)]) {
        let sortedActions = getSortedActions()
        
        if configuration.executeInParallel {
            return executeActionsInParallel(sortedActions)
        } else {
            return executeActionsSequentially(sortedActions)
        }
    }
    
    /// Get enabled actions sorted by priority
    private func getSortedActions() -> [SecurityAction] {
        return configuration.enabledActions.sorted { action1, action2 in
            // Screen lock has highest priority
            if action1 == .screenLock { 
                return true 
            }
            if action2 == .screenLock { 
                return false 
            }
            return action1.rawValue < action2.rawValue
        }
    }
    
    /// Execute actions in parallel
    private func executeActionsInParallel(_ actions: [SecurityAction]) -> ([SecurityAction], [(SecurityAction, Error)]) {
        var executedActions: [SecurityAction] = []
        var failedActions: [(SecurityAction, Error)] = []
        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "com.magsafeguard.results")
        
        for action in actions {
            group.enter()
            queue.async {
                self.executeActionWithResult(action, resultsQueue: resultsQueue, 
                                           executedActions: &executedActions, 
                                           failedActions: &failedActions)
                group.leave()
            }
        }
        
        group.wait()
        return (executedActions, failedActions)
    }
    
    /// Execute actions sequentially
    private func executeActionsSequentially(_ actions: [SecurityAction]) -> ([SecurityAction], [(SecurityAction, Error)]) {
        var executedActions: [SecurityAction] = []
        var failedActions: [(SecurityAction, Error)] = []
        
        for action in actions {
            do {
                try executeAction(action)
                executedActions.append(action)
            } catch {
                failedActions.append((action, error))
                print("[SecurityActionsService] Failed to execute \(action): \(error)")
            }
        }
        
        return (executedActions, failedActions)
    }
    
    /// Execute a single action and update result arrays
    private func executeActionWithResult(_ action: SecurityAction, 
                                       resultsQueue: DispatchQueue,
                                       executedActions: inout [SecurityAction], 
                                       failedActions: inout [(SecurityAction, Error)]) {
        do {
            try executeAction(action)
            resultsQueue.sync {
                executedActions.append(action)
            }
        } catch {
            resultsQueue.sync {
                failedActions.append((action, error))
            }
        }
    }
    
    /// Update configuration
    public func updateConfiguration(_ newConfig: Configuration) {
        queue.async { [weak self] in
            self?.configuration = newConfig
            self?.saveConfiguration()
        }
    }
    
    /// Stop any ongoing actions (like alarm sound)
    public func stopOngoingActions() {
        queue.async { [weak self] in
            self?.systemActions.stopAlarm()
        }
    }
    
    // MARK: - Private Methods
    
    private func executeAction(_ action: SecurityAction) throws {
        print("[SecurityActionsService] Executing action: \(action.displayName)")
        
        switch action {
        case .screenLock:
            try executeScreenLock()
        case .soundAlarm:
            try executeSoundAlarm()
        case .forceLogout:
            try executeForceLogout()
        case .shutdown:
            try executeShutdown()
        case .customScript:
            try executeCustomScript()
        }
    }
    
    private func executeScreenLock() throws {
        try systemActions.lockScreen()
    }
    
    private func executeSoundAlarm() throws {
        try systemActions.playAlarm(volume: configuration.alarmVolume)
    }
    
    private func executeForceLogout() throws {
        try systemActions.forceLogout()
    }
    
    private func executeShutdown() throws {
        try systemActions.scheduleShutdown(afterSeconds: configuration.shutdownDelay)
    }
    
    private func executeCustomScript() throws {
        guard let scriptPath = configuration.customScriptPath else {
            throw SystemActionError.scriptNotFound
        }
        try systemActions.executeScript(at: scriptPath)
    }
    
    // MARK: - Configuration Persistence
    
    private func loadConfiguration() {
        guard let data = UserDefaults.standard.data(forKey: "SecurityActionsConfiguration"),
              let config = try? JSONDecoder().decode(Configuration.self, from: data) else {
            return
        }
        configuration = config
    }
    
    private func saveConfiguration() {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        UserDefaults.standard.set(data, forKey: "SecurityActionsConfiguration")
    }
}

// MARK: - Objective-C Compatibility

@objc public extension SecurityActionsService {
    /// Execute security actions with simple completion
    @objc func executeActionsObjC(completion: @escaping (Bool) -> Void) {
        executeActions { result in
            completion(result.allSucceeded)
        }
    }
    
    /// Check if screen lock is enabled
    @objc var isScreenLockEnabled: Bool {
        return configuration.enabledActions.contains(.screenLock)
    }
    
    /// Enable or disable screen lock
    @objc func setScreenLockEnabled(_ enabled: Bool) {
        var newConfig = configuration
        if enabled {
            newConfig.enabledActions.insert(.screenLock)
        } else {
            newConfig.enabledActions.remove(.screenLock)
        }
        updateConfiguration(newConfig)
    }
}