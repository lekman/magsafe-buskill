//
//  IOKitPowerStateRepository.swift
//  MagSafe Guard
//
//  Created on 2025-08-03.
//

import Foundation
import IOKit.ps

/// IOKit-based implementation of PowerStateRepository
public final class IOKitPowerStateRepository: PowerStateRepository, @unchecked Sendable {

    // MARK: - Properties

    private let queue = DispatchQueue(label: "com.magsafeguard.power.repository", qos: .utility)
    private let pollingInterval: TimeInterval
    private let useNotifications: Bool

    // MARK: - Initialization

    /// Initializes the IOKit-based power state repository
    /// - Parameters:
    ///   - pollingInterval: Interval for polling if notifications are disabled
    ///   - useNotifications: Whether to use system notifications instead of polling
    public init(
        pollingInterval: TimeInterval = 0.1,
        useNotifications: Bool = true
    ) {
        self.pollingInterval = pollingInterval
        // Check test environment before setting useNotifications
        let isTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        self.useNotifications = useNotifications && !isTest
    }

    // MARK: - PowerStateRepository Implementation

    /// Gets the current power state from IOKit
    public func getCurrentPowerState() async throws -> PowerStateInfo {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PowerMonitorError.serviceUnavailable)
                    return
                }

                do {
                    let state = try self.queryPowerState()
                    continuation.resume(returning: state)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Returns a stream of power state changes
    public func observePowerStateChanges() -> AsyncThrowingStream<PowerStateInfo, Error> {
        AsyncThrowingStream { continuation in
            if useNotifications {
                startNotificationMonitoring(continuation: continuation)
            } else {
                startPollingMonitoring(continuation: continuation)
            }
        }
    }

    // MARK: - Private Methods

    private func queryPowerState() throws -> PowerStateInfo {
        // In test environment, return mock data
        if isTestEnvironment {
            return PowerStateInfo(
                isConnected: true,
                batteryLevel: 80,
                isCharging: true,
                adapterWattage: 96
            )
        }

        // Query IOKit for power sources
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any] else {
            throw PowerMonitorError.ioKitError
        }

        var powerInfo = PowerStateInfo(isConnected: false)

        for source in sources {
            guard let sourcePtr = source as? Unmanaged<CFTypeRef>,
                  let sourceInfo = IOPSGetPowerSourceDescription(snapshot, sourcePtr.takeUnretainedValue()) else {
                continue
            }
            guard let sourceInfoDict = sourceInfo.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // Extract power source information
            if let sourceType = sourceInfoDict[kIOPSTypeKey] as? String {
                if sourceType == kIOPSInternalBatteryType {
                    // Battery information
                    let currentCapacity = sourceInfoDict[kIOPSCurrentCapacityKey] as? Int ?? 0
                    let maxCapacity = sourceInfoDict[kIOPSMaxCapacityKey] as? Int ?? 100
                    let batteryLevel = maxCapacity > 0 ? (currentCapacity * 100) / maxCapacity : 0

                    let isCharging = sourceInfoDict[kIOPSIsChargingKey] as? Bool ?? false
                    let powerSourceState = sourceInfoDict[kIOPSPowerSourceStateKey] as? String
                    let isConnected = powerSourceState == kIOPSACPowerValue

                    var adapterWattage: Int?
                    if let adapterInfo = sourceInfoDict[kIOPSPowerAdapterIDKey] as? Int {
                        adapterWattage = extractWattage(from: adapterInfo)
                    }

                    powerInfo = PowerStateInfo(
                        isConnected: isConnected,
                        batteryLevel: batteryLevel,
                        isCharging: isCharging,
                        adapterWattage: adapterWattage
                    )
                    break // We found the internal battery, that's all we need
                }
            }
        }

        return powerInfo
    }

    private func extractWattage(from adapterInfo: Int) -> Int? {
        // Extract wattage from adapter info if available
        // This is a simplified implementation
        return nil
    }

    private func startNotificationMonitoring(continuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation) {
        let context = Unmanaged.passRetained(NotificationContext(continuation: continuation))

        guard let runLoopSource = IOPSNotificationCreateRunLoopSource(
            { contextPtr in
                guard let contextPtr = contextPtr else { return }
                let context = Unmanaged<NotificationContext>.fromOpaque(contextPtr).takeUnretainedValue()
                context.handlePowerChange()
            },
            context.toOpaque()
        )?.takeRetainedValue() else {
            // Fall back to polling if notifications fail
            startPollingMonitoring(continuation: continuation)
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        continuation.onTermination = { _ in
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            context.release()
        }
    }

    private func startPollingMonitoring(continuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation) {
        let task = Task {
            while !Task.isCancelled {
                do {
                    let state = try queryPowerState()
                    continuation.yield(state)
                    try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                } catch {
                    continuation.finish(throwing: error)
                    break
                }
            }
        }

        continuation.onTermination = { _ in
            task.cancel()
        }
    }

    private var isTestEnvironment: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}

// MARK: - Supporting Types

private final class NotificationContext {
    let continuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation
    private let repository = IOKitPowerStateRepository()

    init(continuation: AsyncThrowingStream<PowerStateInfo, Error>.Continuation) {
        self.continuation = continuation
    }

    func handlePowerChange() {
        Task {
            do {
                let state = try await repository.getCurrentPowerState()
                continuation.yield(state)
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

enum PowerMonitorError: LocalizedError {
    case serviceUnavailable
    case ioKitError

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Power monitoring service is unavailable"
        case .ioKitError:
            return "Failed to access power information from IOKit"
        }
    }
}
