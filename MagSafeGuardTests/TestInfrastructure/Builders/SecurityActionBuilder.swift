//
//  SecurityActionBuilder.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//
//  Test builders for creating security action test data.
//  Provides fluent APIs for constructing test instances with sensible defaults.
//

import Foundation
@testable import MagSafeGuard

/// Builder for creating SecurityActionConfiguration test instances.
public final class SecurityActionConfigurationBuilder {
    private var enabledActions: Set<SecurityActionType> = [.lockScreen]
    private var actionDelay: TimeInterval = 0
    private var alarmVolume: Float = 1.0
    private var shutdownDelay: TimeInterval = 30
    private var customScriptPath: String? = nil
    private var executeInParallel: Bool = false
    
    /// Initialize a new security action configuration builder.
    public init() {}
    
    /// Enable specific actions.
    /// - Parameter actions: Actions to enable
    /// - Returns: Self for chaining
    @discardableResult
    public func enableActions(_ actions: SecurityActionType...) -> SecurityActionConfigurationBuilder {
        self.enabledActions = Set(actions)
        return self
    }
    
    /// Add an action to enabled set.
    /// - Parameter action: Action to add
    /// - Returns: Self for chaining
    @discardableResult
    public func addAction(_ action: SecurityActionType) -> SecurityActionConfigurationBuilder {
        self.enabledActions.insert(action)
        return self
    }
    
    /// Set action delay.
    /// - Parameter delay: Delay in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func actionDelay(_ delay: TimeInterval) -> SecurityActionConfigurationBuilder {
        self.actionDelay = delay
        return self
    }
    
    /// Set alarm volume.
    /// - Parameter volume: Volume level (0.0-1.0)
    /// - Returns: Self for chaining
    @discardableResult
    public func alarmVolume(_ volume: Float) -> SecurityActionConfigurationBuilder {
        self.alarmVolume = min(max(volume, 0), 1)
        return self
    }
    
    /// Set shutdown delay.
    /// - Parameter delay: Shutdown countdown in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func shutdownDelay(_ delay: TimeInterval) -> SecurityActionConfigurationBuilder {
        self.shutdownDelay = delay
        return self
    }
    
    /// Set custom script path.
    /// - Parameter path: Path to script
    /// - Returns: Self for chaining
    @discardableResult
    public func customScriptPath(_ path: String?) -> SecurityActionConfigurationBuilder {
        self.customScriptPath = path
        return self
    }
    
    /// Enable parallel execution.
    /// - Parameter parallel: Whether to execute in parallel
    /// - Returns: Self for chaining
    @discardableResult
    public func executeInParallel(_ parallel: Bool = true) -> SecurityActionConfigurationBuilder {
        self.executeInParallel = parallel
        return self
    }
    
    /// Build the SecurityActionConfiguration instance.
    /// - Returns: Configured SecurityActionConfiguration
    public func build() -> SecurityActionConfiguration {
        return SecurityActionConfiguration(
            enabledActions: enabledActions,
            actionDelay: actionDelay,
            alarmVolume: alarmVolume,
            shutdownDelay: shutdownDelay,
            customScriptPath: customScriptPath,
            executeInParallel: executeInParallel
        )
    }
    
    // MARK: - Preset Configurations
    
    /// Create minimal security preset (only lock screen).
    /// - Returns: Configured builder
    public static func minimal() -> SecurityActionConfigurationBuilder {
        return SecurityActionConfigurationBuilder()
            .enableActions(.lockScreen)
    }
    
    /// Create maximum security preset (all actions).
    /// - Returns: Configured builder
    public static func maximum() -> SecurityActionConfigurationBuilder {
        return SecurityActionConfigurationBuilder()
            .enableActions(.lockScreen, .soundAlarm, .forceLogout, .shutdown)
            .executeInParallel(true)
    }
    
    /// Create testing preset (fast execution).
    /// - Returns: Configured builder
    public static func testing() -> SecurityActionConfigurationBuilder {
        return SecurityActionConfigurationBuilder()
            .enableActions(.lockScreen, .soundAlarm)
            .actionDelay(0)
            .shutdownDelay(1)
            .alarmVolume(0.5)
    }
}

/// Builder for creating SecurityActionRequest test instances.
public final class SecurityActionRequestBuilder {
    private var configuration: SecurityActionConfiguration = .default
    private var trigger: SecurityTrigger = .testTrigger
    private var timestamp: Date = Date()
    
    /// Initialize a new security action request builder.
    public init() {}
    
    /// Set the configuration.
    /// - Parameter configuration: Action configuration
    /// - Returns: Self for chaining
    @discardableResult
    public func configuration(_ configuration: SecurityActionConfiguration) -> SecurityActionRequestBuilder {
        self.configuration = configuration
        return self
    }
    
    /// Configure using a builder.
    /// - Parameter configure: Configuration closure
    /// - Returns: Self for chaining
    @discardableResult
    public func configureWith(_ configure: (SecurityActionConfigurationBuilder) -> SecurityActionConfigurationBuilder) -> SecurityActionRequestBuilder {
        let builder = SecurityActionConfigurationBuilder()
        self.configuration = configure(builder).build()
        return self
    }
    
    /// Set the trigger.
    /// - Parameter trigger: What triggered the request
    /// - Returns: Self for chaining
    @discardableResult
    public func trigger(_ trigger: SecurityTrigger) -> SecurityActionRequestBuilder {
        self.trigger = trigger
        return self
    }
    
    /// Set the timestamp.
    /// - Parameter timestamp: Request timestamp
    /// - Returns: Self for chaining
    @discardableResult
    public func timestamp(_ timestamp: Date) -> SecurityActionRequestBuilder {
        self.timestamp = timestamp
        return self
    }
    
    /// Build the SecurityActionRequest instance.
    /// - Returns: Configured SecurityActionRequest
    public func build() -> SecurityActionRequest {
        return SecurityActionRequest(
            configuration: configuration,
            trigger: trigger,
            timestamp: timestamp
        )
    }
}

/// Builder for creating SecurityActionResult test instances.
public final class SecurityActionResultBuilder {
    private var actionType: SecurityActionType = .lockScreen
    private var success: Bool = true
    private var error: SecurityActionError? = nil
    private var executedAt: Date = Date()
    
    /// Initialize a new security action result builder.
    public init() {}
    
    /// Set the action type.
    /// - Parameter type: Type of action
    /// - Returns: Self for chaining
    @discardableResult
    public func actionType(_ type: SecurityActionType) -> SecurityActionResultBuilder {
        self.actionType = type
        return self
    }
    
    /// Set success status.
    /// - Parameter success: Whether action succeeded
    /// - Returns: Self for chaining
    @discardableResult
    public func success(_ success: Bool) -> SecurityActionResultBuilder {
        self.success = success
        return self
    }
    
    /// Set as failed with error.
    /// - Parameter error: The error that occurred
    /// - Returns: Self for chaining
    @discardableResult
    public func failed(with error: SecurityActionError) -> SecurityActionResultBuilder {
        self.success = false
        self.error = error
        return self
    }
    
    /// Set execution time.
    /// - Parameter date: When executed
    /// - Returns: Self for chaining
    @discardableResult
    public func executedAt(_ date: Date) -> SecurityActionResultBuilder {
        self.executedAt = date
        return self
    }
    
    /// Build the SecurityActionResult instance.
    /// - Returns: Configured SecurityActionResult
    public func build() -> SecurityActionResult {
        return SecurityActionResult(
            actionType: actionType,
            success: success,
            error: error,
            executedAt: executedAt
        )
    }
    
    // MARK: - Convenience Methods
    
    /// Create a successful result.
    /// - Parameter action: Action type
    /// - Returns: Success result
    public static func success(for action: SecurityActionType) -> SecurityActionResult {
        return SecurityActionResultBuilder()
            .actionType(action)
            .success(true)
            .build()
    }
    
    /// Create a failed result.
    /// - Parameters:
    ///   - action: Action type
    ///   - error: Error that occurred
    /// - Returns: Failure result
    public static func failure(for action: SecurityActionType, error: SecurityActionError) -> SecurityActionResult {
        return SecurityActionResultBuilder()
            .actionType(action)
            .failed(with: error)
            .build()
    }
}

/// Builder for creating SecurityActionExecutionResult test instances.
public final class SecurityActionExecutionResultBuilder {
    private var request: SecurityActionRequest
    private var executedActions: [SecurityActionResult] = []
    private var startTime: Date = Date()
    private var endTime: Date = Date()
    
    /// Initialize with a request.
    /// - Parameter request: The original request
    public init(request: SecurityActionRequest) {
        self.request = request
    }
    
    /// Add an executed action result.
    /// - Parameter result: Action result to add
    /// - Returns: Self for chaining
    @discardableResult
    public func addResult(_ result: SecurityActionResult) -> SecurityActionExecutionResultBuilder {
        self.executedActions.append(result)
        return self
    }
    
    /// Add multiple executed action results.
    /// - Parameter results: Action results to add
    /// - Returns: Self for chaining
    @discardableResult
    public func addResults(_ results: [SecurityActionResult]) -> SecurityActionExecutionResultBuilder {
        self.executedActions.append(contentsOf: results)
        return self
    }
    
    /// Set execution times.
    /// - Parameters:
    ///   - start: Start time
    ///   - end: End time
    /// - Returns: Self for chaining
    @discardableResult
    public func executionTime(start: Date, end: Date) -> SecurityActionExecutionResultBuilder {
        self.startTime = start
        self.endTime = end
        return self
    }
    
    /// Set execution duration.
    /// - Parameter duration: Duration in seconds
    /// - Returns: Self for chaining
    @discardableResult
    public func duration(_ duration: TimeInterval) -> SecurityActionExecutionResultBuilder {
        self.endTime = startTime.addingTimeInterval(duration)
        return self
    }
    
    /// Build the SecurityActionExecutionResult instance.
    /// - Returns: Configured SecurityActionExecutionResult
    public func build() -> SecurityActionExecutionResult {
        return SecurityActionExecutionResult(
            request: request,
            executedActions: executedActions,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    /// Create a successful execution result.
    /// - Parameter request: The request
    /// - Returns: Successful execution result
    public static func allSuccessful(for request: SecurityActionRequest) -> SecurityActionExecutionResult {
        let builder = SecurityActionExecutionResultBuilder(request: request)
        
        for action in request.configuration.enabledActions {
            builder.addResult(.success(for: action))
        }
        
        return builder.duration(0.5).build()
    }
}