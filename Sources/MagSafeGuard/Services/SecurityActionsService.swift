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
        
        static let `default` = Configuration(
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
    private var _isExecuting = false
    private let executingLock = NSLock()
    
    public var isExecuting: Bool {
        executingLock.lock()
        defer { executingLock.unlock() }
        return _isExecuting
    }
    
    /// Serial queue for thread safety
    private let queue = DispatchQueue(label: "com.magsafeguard.securityactions", qos: .userInitiated)
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = Configuration.default
        self.systemActions = MacSystemActions()
        loadConfiguration()
    }
    
    /// Initialize with custom system actions (for testing)
    internal init(systemActions: SystemActionsProtocol) {
        self.configuration = Configuration.default
        self.systemActions = systemActions
        loadConfiguration()
    }
    
    /// Reset configuration to default (for testing)
    internal func resetToDefault() {
        queue.sync {
            self.configuration = Configuration.default
            UserDefaults.standard.removeObject(forKey: "SecurityActionsConfiguration")
        }
    }
    
    // MARK: - Public Methods
    
    /// Execute all enabled security actions
    /// - Parameter completion: Callback with execution result
    public func executeActions(completion: @escaping (ExecutionResult) -> Void) {
        // Use lock to atomically check and set isExecuting
        executingLock.lock()
        if _isExecuting {
            executingLock.unlock()
            print("[SecurityActionsService] Actions already executing, ignoring request")
            return
        }
        _isExecuting = true
        executingLock.unlock()
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let startTime = Date()
            
            // Apply configured delay
            if self.configuration.actionDelay > 0 {
                print("[SecurityActionsService] Waiting \(self.configuration.actionDelay)s before executing actions")
                Thread.sleep(forTimeInterval: self.configuration.actionDelay)
            }
            
            var executedActions: [SecurityAction] = []
            var failedActions: [(SecurityAction, Error)] = []
            
            // Sort actions by priority
            let sortedActions = self.configuration.enabledActions.sorted { action1, action2 in
                // Screen lock has highest priority
                if action1 == .screenLock { return true }
                if action2 == .screenLock { return false }
                return action1.rawValue < action2.rawValue
            }
            
            if self.configuration.executeInParallel {
                // Execute actions in parallel
                let group = DispatchGroup()
                let resultsQueue = DispatchQueue(label: "com.magsafeguard.results")
                
                for action in sortedActions {
                    group.enter()
                    self.queue.async {
                        do {
                            try self.executeAction(action)
                            resultsQueue.sync {
                                executedActions.append(action)
                            }
                        } catch {
                            resultsQueue.sync {
                                failedActions.append((action, error))
                            }
                        }
                        group.leave()
                    }
                }
                
                group.wait()
            } else {
                // Execute actions sequentially
                for action in sortedActions {
                    do {
                        try self.executeAction(action)
                        executedActions.append(action)
                    } catch {
                        failedActions.append((action, error))
                        print("[SecurityActionsService] Failed to execute \(action): \(error)")
                    }
                }
            }
            
            self.executingLock.lock()
            self._isExecuting = false
            self.executingLock.unlock()
            
            let result = ExecutionResult(
                executedActions: executedActions,
                failedActions: failedActions,
                timestamp: startTime
            )
            
            DispatchQueue.main.async {
                completion(result)
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