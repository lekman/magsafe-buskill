//
//  SentryManager.swift
//  MagSafe Guard
//
//  Sentry integration for crash reporting and telemetry
//

import Foundation
import Sentry

/// Manages Sentry integration for crash reporting and telemetry
public final class SentryManager {
    public static let shared = SentryManager()
    
    private var isInitialized = false
    private let queue = DispatchQueue(label: "com.magsafeguard.sentry")
    
    // Sentry DSN from environment
    private var sentryDSN: String? {
        ProcessInfo.processInfo.environment["SENTRY_DSN"]
    }
    
    private init() {}
    
    /// Initialize Sentry if enabled via feature flags
    public func initialize() {
        guard FeatureFlags.shared.isSentryEnabled else {
            Log.info("Sentry is disabled via feature flags", category: .general)
            return
        }
        
        guard let dsn = sentryDSN, !dsn.isEmpty else {
            Log.warning("Sentry enabled but SENTRY_DSN not found in environment", category: .general)
            return
        }
        
        queue.sync {
            guard !isInitialized else { return }
            
            do {
                SentrySDK.start { options in
                    options.dsn = dsn
                    options.debug = FeatureFlags.shared.isEnabled(.sentryDebug)
                    options.environment = self.currentEnvironment()
                    options.tracesSampleRate = 0.1
                    options.attachViewHierarchy = true
                    options.enableAutoSessionTracking = true
                    options.sessionTrackingIntervalMillis = 30000
                    
                    // Set release version
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        options.releaseName = "magsafe-guard@\(version)+\(build)"
                    }
                    
                    // Add context
                    options.beforeSend = { event in
                        event.tags?["feature_flags"] = self.getEnabledFlagsString()
                        return event
                    }
                    
                    // Only send PII in debug builds
                    options.sendDefaultPii = FeatureFlags.shared.isEnabled(.sentryDebug)
                }
                
                isInitialized = true
                
                Log.info("Sentry initialized successfully", category: .general)
                Log.info("Environment: \(self.currentEnvironment())", category: .general)
                
                // Set user context
                setUserContext()
                
                // Add feature flag context
                updateFeatureFlagContext()
                
                // Add breadcrumb
                addBreadcrumb("Sentry initialized", category: "app.lifecycle")
                
            } catch {
                Log.error("Failed to initialize Sentry: \(error)", category: .general)
            }
        }
    }
    
    /// Capture an error
    public func captureError(_ error: Error, context: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "additional_context")
            }
            scope.setTag(value: "error", key: "type")
        }
    }
    
    /// Capture a message
    public func captureMessage(_ message: String, level: LogLevel = .info) {
        guard isInitialized else { return }
        
        let sentryLevel: SentryLevel
        switch level {
        case .debug: sentryLevel = .debug
        case .info: sentryLevel = .info
        case .warning: sentryLevel = .warning
        case .error: sentryLevel = .error
        }
        
        SentrySDK.capture(message: message, level: sentryLevel)
    }
    
    /// Add a breadcrumb for debugging
    public func addBreadcrumb(_ message: String, category: String, data: [String: Any]? = nil) {
        guard isInitialized else { return }
        
        let crumb = Breadcrumb()
        crumb.message = message
        crumb.category = category
        crumb.data = data
        crumb.timestamp = Date()
        SentrySDK.addBreadcrumb(crumb)
    }
    
    /// Start a transaction for performance monitoring
    public func startTransaction(name: String, operation: String) -> Any? {
        guard isInitialized, FeatureFlags.shared.isPerformanceMetricsEnabled else { return nil }
        
        return SentrySDK.startTransaction(name: name, operation: operation)
    }
    
    /// Update feature flag context
    public func updateFeatureFlagContext() {
        guard isInitialized else { return }
        
        let enabledFlags = getEnabledFlagsString()
        
        SentrySDK.configureScope { scope in
            scope.setContext(value: [
                "enabled_flags": enabledFlags,
                "total_flags": FeatureFlags.Flag.allCases.count
            ], key: "feature_flags")
        }
    }
    
    // MARK: - Private Helpers
    
    private func currentEnvironment() -> String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }
    
    private func setUserContext() {
        let user = User(userId: getMachineIdentifier())
        user.ipAddress = "{{auto}}" // Let Sentry determine IP if sendDefaultPii is true
        SentrySDK.setUser(user)
    }
    
    private func getMachineIdentifier() -> String {
        // Get a stable machine identifier (anonymized)
        if let hardwareUUID = getHardwareUUID() {
            return hardwareUUID.replacingOccurrences(of: "-", with: "").lowercased()
        }
        return "unknown"
    }
    
    private func getHardwareUUID() -> String? {
        let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matchingDict)
        defer { IOObjectRelease(service) }
        
        let cfstring = "IOPlatformUUID" as CFString
        if let uuid = IORegistryEntryCreateCFProperty(service, cfstring, kCFAllocatorDefault, 0)?.takeUnretainedValue() as? String {
            return uuid
        }
        return nil
    }
    
    private func getEnabledFlagsString() -> String {
        let enabledFlags = FeatureFlags.shared.allFlags()
            .filter { $0.value }
            .map { $0.key.rawValue }
            .sorted()
            .joined(separator: ",")
        return enabledFlags
    }
}

// MARK: - Crash Handler

extension SentryManager {
    /// Report a handled exception
    public func reportException(_ exception: NSException, context: [String: Any]? = nil) {
        captureError(NSError(domain: exception.name.rawValue,
                           code: -1,
                           userInfo: [NSLocalizedDescriptionKey: exception.reason ?? "Unknown"]),
                    context: context)
    }
    
    /// Report app lifecycle events
    public func reportAppLifecycle(_ event: String) {
        addBreadcrumb(event, category: "app.lifecycle", data: [
            "timestamp": Date().timeIntervalSince1970,
            "memory_usage": getMemoryUsage()
        ])
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0
    }
}

// MARK: - IOKit imports

import IOKit