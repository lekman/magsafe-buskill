//
//  FeatureFlags.swift
//  MagSafe Guard
//
//  Feature flag management system for progressive rollout and debugging
//

import Foundation

/// Centralized feature flag management
public final class FeatureFlags {
    public static let shared = FeatureFlags()
    
    /// Available feature flags
    public enum Flag: String, CaseIterable {
        // Core Services
        case powerMonitoring = "FEATURE_POWER_MONITORING"
        case accessibilityManager = "FEATURE_ACCESSIBILITY"
        case notificationService = "FEATURE_NOTIFICATIONS"
        case authenticationService = "FEATURE_AUTHENTICATION"
        case autoArmManager = "FEATURE_AUTO_ARM"
        case locationManager = "FEATURE_LOCATION"
        case networkMonitor = "FEATURE_NETWORK_MONITOR"
        case securityEvidence = "FEATURE_SECURITY_EVIDENCE"
        case cloudSync = "FEATURE_CLOUD_SYNC"
        
        // Telemetry
        case sentryEnabled = "SENTRY_ENABLED"
        case sentryDebug = "SENTRY_DEBUG"
        case performanceMetrics = "FEATURE_PERFORMANCE_METRICS"
        
        // Debug Features
        case verboseLogging = "DEBUG_VERBOSE_LOGGING"
        case mockServices = "DEBUG_MOCK_SERVICES"
        case disableSandbox = "DEBUG_DISABLE_SANDBOX"
        
        var defaultValue: Bool {
            switch self {
            // Core services enabled by default
            case .powerMonitoring, .accessibilityManager, .notificationService:
                return true
            case .authenticationService, .autoArmManager:
                return true
                
            // Optional features disabled by default
            case .locationManager, .networkMonitor, .securityEvidence, .cloudSync:
                return false
                
            // Telemetry disabled by default
            case .sentryEnabled, .sentryDebug, .performanceMetrics:
                return false
                
            // Debug features disabled by default
            case .verboseLogging, .mockServices, .disableSandbox:
                return false
            }
        }
        
        var description: String {
            switch self {
            case .powerMonitoring:
                return "Power adapter monitoring (core functionality)"
            case .accessibilityManager:
                return "Accessibility permissions for system actions"
            case .notificationService:
                return "System notifications"
            case .authenticationService:
                return "Touch ID/password authentication"
            case .autoArmManager:
                return "Automatic arming based on conditions"
            case .locationManager:
                return "Location-based features"
            case .networkMonitor:
                return "Network-based auto-arm"
            case .securityEvidence:
                return "Security evidence collection"
            case .cloudSync:
                return "iCloud sync functionality"
            case .sentryEnabled:
                return "Sentry crash reporting and telemetry"
            case .sentryDebug:
                return "Sentry debug mode"
            case .performanceMetrics:
                return "Performance metrics tracking"
            case .verboseLogging:
                return "Verbose debug logging"
            case .mockServices:
                return "Use mock services for testing"
            case .disableSandbox:
                return "Disable app sandbox (development only)"
            }
        }
    }
    
    private var flags: [Flag: Bool] = [:]
    private let queue = DispatchQueue(label: "com.magsafeguard.featureflags")
    
    private init() {
        loadFlags()
    }
    
    /// Load flags from environment and .env file
    private func loadFlags() {
        queue.sync {
            // First, set default values
            for flag in Flag.allCases {
                flags[flag] = flag.defaultValue
            }
            
            // Then, override with environment variables
            for flag in Flag.allCases {
                if let envValue = ProcessInfo.processInfo.environment[flag.rawValue] {
                    flags[flag] = (envValue.lowercased() == "true" || envValue == "1")
                }
            }
            
            // Load from .env file if it exists
            loadEnvFile()
            
            #if DEBUG
            Log.debug("Feature flags loaded: \(flags)", category: .general)
            #endif
        }
    }
    
    /// Load flags from .env file
    private func loadEnvFile() {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let envPath = "\(currentPath)/.env"
        
        guard fileManager.fileExists(atPath: envPath),
              let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            return
        }
        
        let lines = envContent.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Parse KEY=VALUE
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                
                // Check if it's a feature flag
                if let flag = Flag(rawValue: key) {
                    flags[flag] = (value.lowercased() == "true" || value == "1")
                }
            }
        }
    }
    
    /// Check if a feature flag is enabled
    public func isEnabled(_ flag: Flag) -> Bool {
        queue.sync {
            return flags[flag] ?? flag.defaultValue
        }
    }
    
    /// Set a feature flag value (for testing)
    public func setFlag(_ flag: Flag, enabled: Bool) {
        queue.sync {
            flags[flag] = enabled
        }
    }
    
    /// Get all current flag states
    public func allFlags() -> [Flag: Bool] {
        queue.sync {
            return flags
        }
    }
    
    /// Export current flags to .env format
    public func exportToEnv() -> String {
        queue.sync {
            var lines: [String] = [
                "# MagSafe Guard Feature Flags",
                "# Generated on \(Date())",
                ""
            ]
            
            // Group flags by category
            let coreFlags = Flag.allCases.filter { $0.rawValue.hasPrefix("FEATURE_") && !$0.rawValue.contains("DEBUG") }
            let telemetryFlags = Flag.allCases.filter { $0.rawValue.contains("SENTRY") || $0.rawValue.contains("METRICS") }
            let debugFlags = Flag.allCases.filter { $0.rawValue.hasPrefix("DEBUG_") }
            
            lines.append("# Core Features")
            for flag in coreFlags {
                let value = flags[flag] ?? flag.defaultValue
                lines.append("\(flag.rawValue)=\(value)")
            }
            
            lines.append("")
            lines.append("# Telemetry")
            for flag in telemetryFlags {
                let value = flags[flag] ?? flag.defaultValue
                lines.append("\(flag.rawValue)=\(value)")
            }
            
            lines.append("")
            lines.append("# Debug Options")
            for flag in debugFlags {
                let value = flags[flag] ?? flag.defaultValue
                lines.append("\(flag.rawValue)=\(value)")
            }
            
            return lines.joined(separator: "\n")
        }
    }
    
    /// Convenience method for checking multiple flags
    public func areEnabled(_ flags: Flag...) -> Bool {
        return flags.allSatisfy { isEnabled($0) }
    }
    
    /// Convenience method for checking if any flag is enabled
    public func isAnyEnabled(_ flags: Flag...) -> Bool {
        return flags.contains { isEnabled($0) }
    }
}

// MARK: - Convenience Extensions

public extension FeatureFlags {
    /// Quick access to common flag states
    var isPowerMonitoringEnabled: Bool { isEnabled(.powerMonitoring) }
    var isAccessibilityEnabled: Bool { isEnabled(.accessibilityManager) }
    var isNotificationsEnabled: Bool { isEnabled(.notificationService) }
    var isAuthenticationEnabled: Bool { isEnabled(.authenticationService) }
    var isAutoArmEnabled: Bool { isEnabled(.autoArmManager) }
    var isLocationEnabled: Bool { isEnabled(.locationManager) }
    var isNetworkMonitorEnabled: Bool { isEnabled(.networkMonitor) }
    var isSecurityEvidenceEnabled: Bool { isEnabled(.securityEvidence) }
    var isCloudSyncEnabled: Bool { isEnabled(.cloudSync) }
    var isSentryEnabled: Bool { isEnabled(.sentryEnabled) }
    var isPerformanceMetricsEnabled: Bool { isEnabled(.performanceMetrics) }
    var isVerboseLoggingEnabled: Bool { isEnabled(.verboseLogging) }
}