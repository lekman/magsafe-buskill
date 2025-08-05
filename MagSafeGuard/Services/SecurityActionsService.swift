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
import MagSafeGuardCore

/// Service responsible for executing security actions when theft is detected.
///
/// SecurityActionsService orchestrates the execution of protective measures when
/// power disconnection indicates a potential theft attempt. It provides configurable
/// actions ranging from screen locking to system shutdown, with support for both
/// sequential and parallel execution modes.
///
/// ## Security Actions
///
/// - **Screen Lock**: Immediately lock the screen requiring authentication
/// - **Sound Alarm**: Play loud alarm to deter theft and alert nearby people
/// - **Force Logout**: Log out all users and lock the system
/// - **System Shutdown**: Shut down the computer after a configurable delay
/// - **Custom Script**: Execute user-defined shell scripts for custom actions
///
/// ## Configuration
///
/// Actions are fully configurable with support for:
/// - Individual action enable/disable
/// - Execution delays and timeouts
/// - Parallel vs sequential execution
/// - Custom script paths and parameters
///
/// ## Usage
///
/// ```swift
/// SecurityActionsService.shared.executeActions { result in
///     if result.allSucceeded {
///         Log.info("All security actions completed successfully")
///     } else {
///         Log.error("\(result.failedActions.count) actions failed")
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// All operations are thread-safe with atomic execution state tracking.
/// Completion handlers are called on the main queue for UI safety.
public class SecurityActionsService {

  // MARK: - Types

  /// Available security actions that can be executed on theft detection.
  ///
  /// Each action represents a specific protective measure with different
  /// security implications and user impact. Actions can be combined and
  /// configured for layered security approaches.
  public enum SecurityAction: String, CaseIterable, Codable {
    /// Lock the screen immediately requiring authentication
    case screenLock = "screen_lock"
    /// Play a loud alarm sound to deter theft
    case soundAlarm = "sound_alarm"
    /// Force logout all users and lock the system
    case forceLogout = "force_logout"
    /// Shutdown the system after a delay
    case shutdown = "shutdown"
    /// Execute a custom shell script
    case customScript = "custom_script"

    /// Human-readable name for the security action.
    ///
    /// Used in UI components to display action names to users.
    var displayName: String {
      switch self {
      case .screenLock: return "Lock Screen"
      case .soundAlarm: return "Sound Alarm"
      case .forceLogout: return "Force Logout"
      case .shutdown: return "System Shutdown"
      case .customScript: return "Custom Script"
      }
    }

    /// Detailed description of what the security action does.
    ///
    /// Provides users with clear information about the impact
    /// and behavior of each security action.
    var description: String {
      switch self {
      case .screenLock: return "Immediately lock the screen requiring authentication"
      case .soundAlarm: return "Play a loud alarm sound to deter theft"
      case .forceLogout: return "Force logout all users and lock screen"
      case .shutdown: return "Shutdown the system after a countdown"
      case .customScript: return "Execute a custom shell script"
      }
    }

    /// Whether this action is enabled by default.
    ///
    /// Determines the initial state when setting up security actions.
    /// Screen lock is the only action enabled by default for safety.
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

  /// Configuration for security actions execution.
  ///
  /// Defines which actions are enabled and how they should be executed,
  /// including timing, volume, and execution order preferences.
  public struct Configuration: Codable {
    /// Set of enabled security actions to execute
    var enabledActions: Set<SecurityAction>
    /// Delay in seconds before executing any actions
    var actionDelay: TimeInterval
    /// Alarm volume level (0.0 to 1.0)
    var alarmVolume: Float
    /// Delay in seconds before system shutdown
    var shutdownDelay: TimeInterval
    /// Path to custom script file
    var customScriptPath: String?
    /// Whether to execute actions in parallel or sequentially
    var executeInParallel: Bool

    static let defaultConfiguration = Configuration(
      enabledActions: [.screenLock],
      actionDelay: 0,  // Immediate by default
      alarmVolume: 1.0,
      shutdownDelay: 30,  // 30 seconds before shutdown
      customScriptPath: nil,
      executeInParallel: false
    )
  }

  /// Result of executing security actions.
  ///
  /// Contains detailed information about which actions succeeded or failed,
  /// enabling proper error handling and user feedback.
  public struct ExecutionResult {
    /// Actions that executed successfully
    let executedActions: [SecurityAction]
    /// Actions that failed with their specific errors
    let failedActions: [(action: SecurityAction, error: Error)]
    /// When the execution started
    let timestamp: Date

    /// Whether all configured actions executed successfully.
    ///
    /// Returns true only if no actions failed. Use this for simple
    /// success/failure determination.
    var allSucceeded: Bool {
      return failedActions.isEmpty
    }
  }

  // MARK: - Properties

  /// Shared instance for singleton pattern.
  ///
  /// The shared instance provides global access to security actions functionality.
  /// All components should use this instance for consistent configuration.
  public static let shared = SecurityActionsService()

  /// Current security actions configuration.
  ///
  /// Contains the active settings for which actions are enabled and how
  /// they should be executed. Configuration is persisted automatically.
  private(set) public var configuration: Configuration

  /// System actions implementation
  private let systemActions: SystemActionsProtocol

  /// Flag to track if actions are currently executing
  private var isCurrentlyExecuting = false
  private let executingLock = NSLock()

  /// Whether security actions are currently being executed.
  ///
  /// Thread-safe property that indicates if an execution is in progress.
  /// Used to prevent concurrent executions and provide status information.
  public var isExecuting: Bool {
    executingLock.lock()
    defer { executingLock.unlock() }
    return isCurrentlyExecuting
  }

  /// Serial queue for thread safety
  private let queue = DispatchQueue(label: "com.magsafeguard.securityactions", qos: .userInitiated)
  
  // MARK: - Rate Limiting
  
  /// Last execution timestamp for rate limiting
  private var lastExecutionTime: Date?
  
  /// Minimum time interval between executions (in seconds)
  private let minimumExecutionInterval: TimeInterval = 5.0
  
  /// Maximum number of executions within the time window
  private let maxExecutionsPerWindow = 10
  
  /// Time window for rate limiting (in seconds)
  private let rateLimitWindow: TimeInterval = 60.0
  
  /// Execution history for rate limiting
  private var executionHistory: [Date] = []
  
  /// Lock for thread-safe access to rate limiting properties
  private let rateLimitLock = NSLock()
  
  // MARK: - Circuit Breaker
  
  /// Circuit breaker state
  private enum CircuitBreakerState {
    case closed
    case open(until: Date)
    case halfOpen
  }
  
  /// Current circuit breaker state
  private var circuitBreakerState: CircuitBreakerState = .closed
  
  /// Number of consecutive failures
  private var consecutiveFailures = 0
  
  /// Maximum consecutive failures before opening circuit
  private let maxConsecutiveFailures = 3
  
  /// Time to keep circuit open (in seconds)
  private let circuitOpenDuration: TimeInterval = 60.0
  
  /// Lock for circuit breaker state
  private let circuitBreakerLock = NSLock()

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

  /// Execute all enabled security actions.
  ///
  /// Initiates execution of all configured security actions according to
  /// the current configuration. Actions are executed either sequentially
  /// or in parallel based on configuration settings.
  ///
  /// The execution includes:
  /// - Pre-execution delay if configured
  /// - Action prioritization (screen lock first)
  /// - Error handling and result collection
  /// - Thread-safe execution state management
  ///
  /// - Parameter completion: Result handler called on main queue
  ///
  /// - Note: Only one execution can be active at a time. Subsequent
  ///   calls while executing are ignored to prevent conflicts.
  public func executeActions(completion: @escaping (ExecutionResult) -> Void) {
    // Check circuit breaker first
    if let circuitError = checkCircuitBreaker() {
      Log.warning("Circuit breaker open: \(circuitError)", category: .security)
      DispatchQueue.main.async {
        completion(ExecutionResult(
          executedActions: [],
          failedActions: [(SecurityAction.screenLock, circuitError)],
          timestamp: Date()
        ))
      }
      return
    }
    
    // Check rate limiting
    if !checkRateLimit() {
      Log.warning("Rate limit exceeded for security actions", category: .security)
      DispatchQueue.main.async {
        completion(ExecutionResult(
          executedActions: [],
          failedActions: [(SecurityAction.screenLock, MagSafeGuardDomain.SecurityActionError.rateLimitExceeded)],
          timestamp: Date()
        ))
      }
      return
    }
    
    guard trySetExecuting() else {
      Log.warning("Actions already executing, ignoring request", category: .security)
      return
    }

    queue.async { [weak self] in
      guard let self = self else { return }
      self.performExecution(completion: completion)
    }
  }

  // MARK: - Rate Limiting Methods
  
  /// Check if execution is allowed based on rate limiting rules
  private func checkRateLimit() -> Bool {
    rateLimitLock.lock()
    defer { rateLimitLock.unlock() }
    
    let now = Date()
    
    // Check minimum interval between executions
    if let lastExecution = lastExecutionTime {
      let timeSinceLastExecution = now.timeIntervalSince(lastExecution)
      if timeSinceLastExecution < minimumExecutionInterval {
        Log.warning("Execution denied: minimum interval not met (\(timeSinceLastExecution)s < \(minimumExecutionInterval)s)", category: .security)
        return false
      }
    }
    
    // Clean up old execution history
    executionHistory = executionHistory.filter { execution in
      now.timeIntervalSince(execution) <= rateLimitWindow
    }
    
    // Check if we've exceeded the rate limit
    if executionHistory.count >= maxExecutionsPerWindow {
      Log.warning("Execution denied: rate limit exceeded (\(executionHistory.count) executions in \(rateLimitWindow)s)", category: .security)
      return false
    }
    
    // Record this execution
    lastExecutionTime = now
    executionHistory.append(now)
    
    return true
  }
  
  // MARK: - Circuit Breaker Methods
  
  /// Check if circuit breaker allows execution
  private func checkCircuitBreaker() -> MagSafeGuardDomain.SecurityActionError? {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }
    
    switch circuitBreakerState {
    case .closed:
      return nil
      
    case .open(let until):
      if Date() >= until {
        // Try to move to half-open state
        circuitBreakerState = .halfOpen
        Log.info("Circuit breaker moved to half-open state", category: .security)
        return nil
      } else {
        return .systemError(description: "Circuit breaker is open. Too many consecutive failures.")
      }
      
    case .halfOpen:
      // Allow one attempt in half-open state
      return nil
    }
  }
  
  /// Record execution success
  private func recordSuccess() {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }
    
    consecutiveFailures = 0
    
    // If in half-open state, close the circuit
    if case .halfOpen = circuitBreakerState {
      circuitBreakerState = .closed
      Log.info("Circuit breaker closed after successful execution", category: .security)
    }
  }
  
  /// Record execution failure
  private func recordFailure() {
    circuitBreakerLock.lock()
    defer { circuitBreakerLock.unlock() }
    
    consecutiveFailures += 1
    
    // Check if we should open the circuit
    if consecutiveFailures >= maxConsecutiveFailures {
      let reopenTime = Date().addingTimeInterval(circuitOpenDuration)
      circuitBreakerState = .open(until: reopenTime)
      Log.error("Circuit breaker opened due to \(consecutiveFailures) consecutive failures", category: .security)
    }
    
    // If in half-open state, reopen the circuit
    if case .halfOpen = circuitBreakerState {
      let reopenTime = Date().addingTimeInterval(circuitOpenDuration)
      circuitBreakerState = .open(until: reopenTime)
      Log.error("Circuit breaker reopened after failure in half-open state", category: .security)
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
    
    // Update circuit breaker based on result
    if result.allSucceeded {
      recordSuccess()
    } else {
      recordFailure()
    }

    DispatchQueue.main.async {
      completion(result)
    }
  }

  /// Apply configured delay before executing actions
  private func applyActionDelay() {
    if configuration.actionDelay > 0 {
      Log.info(
        "Waiting \(configuration.actionDelay)s before executing actions", category: .security)
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
  private func executeActionsInParallel(
    _ actions: [SecurityAction]
  ) -> ([SecurityAction], [(SecurityAction, Error)]) {
    var executedActions: [SecurityAction] = []
    var failedActions: [(SecurityAction, Error)] = []
    let group = DispatchGroup()
    let resultsQueue = DispatchQueue(label: "com.magsafeguard.results")

    for action in actions {
      group.enter()
      queue.async {
        self.executeActionWithResult(
          action,
          resultsQueue: resultsQueue,
          executedActions: &executedActions,
          failedActions: &failedActions
        )
        group.leave()
      }
    }

    group.wait()
    return (executedActions, failedActions)
  }

  /// Execute actions sequentially
  private func executeActionsSequentially(
    _ actions: [SecurityAction]
  ) -> ([SecurityAction], [(SecurityAction, Error)]) {
    var executedActions: [SecurityAction] = []
    var failedActions: [(SecurityAction, Error)] = []

    for action in actions {
      do {
        try executeAction(action)
        executedActions.append(action)
      } catch {
        failedActions.append((action, error))
        Log.error("Failed to execute \(action)", error: error, category: .security)
      }
    }

    return (executedActions, failedActions)
  }

  /// Execute a single action and update result arrays
  private func executeActionWithResult(
    _ action: SecurityAction,
    resultsQueue: DispatchQueue,
    executedActions: inout [SecurityAction],
    failedActions: inout [(SecurityAction, Error)]
  ) {
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

  /// Update the security actions configuration.
  ///
  /// Applies new configuration settings and persists them for future use.
  /// Changes take effect immediately for subsequent action executions.
  ///
  /// - Parameter newConfig: New configuration to apply
  public func updateConfiguration(_ newConfig: Configuration) {
    queue.async { [weak self] in
      self?.configuration = newConfig
      self?.saveConfiguration()
    }
  }

  /// Stop any ongoing actions that may continue after execution.
  ///
  /// Terminates persistent actions like alarm sounds that may continue
  /// playing after the initial execution. Does not affect completed
  /// actions like screen locking.
  public func stopOngoingActions() {
    queue.async { [weak self] in
      self?.systemActions.stopAlarm()
    }
  }

  // MARK: - Private Methods

  private func executeAction(_ action: SecurityAction) throws {
    Log.info("Executing action: \(action.displayName)", category: .security)

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
      let config = try? JSONDecoder().decode(Configuration.self, from: data)
    else {
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

/// Objective-C compatible extension for SecurityActionsService
@objc extension SecurityActionsService {
  /// Execute security actions with simple boolean completion.
  ///
  /// Objective-C compatible method that provides basic success/failure
  /// indication without detailed error information.
  ///
  /// - Parameter completion: Called with true if all actions succeeded
  public func executeActionsObjC(completion: @escaping (Bool) -> Void) {
    executeActions { result in
      completion(result.allSucceeded)
    }
  }

  /// Whether screen lock action is currently enabled.
  ///
  /// Objective-C compatible property for checking if the most basic
  /// security action (screen lock) is configured.
  public var isScreenLockEnabled: Bool {
    return configuration.enabledActions.contains(.screenLock)
  }

  /// Enable or disable the screen lock security action.
  ///
  /// Objective-C compatible method for toggling the screen lock action.
  /// Changes are persisted automatically.
  ///
  /// - Parameter enabled: True to enable screen lock, false to disable
  public func setScreenLockEnabled(_ enabled: Bool) {
    var newConfig = configuration
    if enabled {
      newConfig.enabledActions.insert(.screenLock)
    } else {
      newConfig.enabledActions.remove(.screenLock)
    }
    updateConfiguration(newConfig)
  }
}
