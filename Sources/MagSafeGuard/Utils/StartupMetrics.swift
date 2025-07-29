//
//  StartupMetrics.swift
//  MagSafe Guard
//
//  Tracks startup performance metrics for debugging and optimization
//

import Foundation

/// Tracks startup performance metrics
public class StartupMetrics {
    public static let shared = StartupMetrics()

    private var metrics: [String: TimeInterval] = [:]
    private var startTime: CFAbsoluteTime = 0
    private let queue = DispatchQueue(label: "com.magsafeguard.metrics")

    private init() {}

    /// Start measuring startup time
    public func startMeasuring() {
        queue.sync {
            startTime = CFAbsoluteTimeGetCurrent()
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            metrics["startup_begin"] = elapsed

            #if DEBUG
            Log.debug("Startup milestone 'startup_begin': \(String(format: "%.3f", elapsed))s", category: .general)
            #endif
        }
    }

    /// Record a startup milestone
    public func recordMilestone(_ name: String) {
        queue.sync {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            metrics[name] = elapsed

            #if DEBUG
            Log.debug("Startup milestone '\(name)': \(String(format: "%.3f", elapsed))s", category: .general)
            #endif
        }
    }

    /// Get total startup time
    public func getTotalTime() -> TimeInterval {
        queue.sync {
            return CFAbsoluteTimeGetCurrent() - startTime
        }
    }

    /// Generate a performance report
    public func generateReport() -> String {
        queue.sync {
            var report = "Startup Performance Report:\n"
            report += "Total time: \(String(format: "%.3f", getTotalTime()))s\n\n"

            for (milestone, time) in metrics.sorted(by: { $0.value < $1.value }) {
                report += "  \(milestone): \(String(format: "%.3f", time))s\n"
            }

            return report
        }
    }

    /// Log the performance report
    public func logReport() {
        let report = generateReport()
        Log.info(report, category: .general)
    }
}
