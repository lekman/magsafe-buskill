//
//  RateLimiter.swift
//  MagSafe Guard
//
//  Created on 2025-08-05.
//

import Foundation
import MagSafeGuardDomain

/// Token bucket based rate limiter for resource protection
public actor RateLimiter: RateLimiterProtocol {

    // MARK: - Types

    private struct Bucket {
        var tokens: Int
        var lastRefill: Date
        let capacity: Int
        let refillRate: TimeInterval // seconds per token

        mutating func refill() {
            let now = Date()
            let elapsed = now.timeIntervalSince(lastRefill)
            let tokensToAdd = Int(elapsed / refillRate)

            if tokensToAdd > 0 {
                tokens = min(capacity, tokens + tokensToAdd)
                lastRefill = now
            }
        }

        mutating func consume() -> Bool {
            refill()
            if tokens > 0 {
                tokens -= 1
                return true
            }
            return false
        }
    }

    // MARK: - Properties

    private var buckets: [String: Bucket] = [:]
    private let defaultCapacity: Int
    private let defaultRefillRate: TimeInterval

    // MARK: - Initialization

    /// Initialize rate limiter with default settings
    /// - Parameters:
    ///   - defaultCapacity: Default token bucket capacity
    ///   - defaultRefillRate: Default seconds per token refill
    public init(defaultCapacity: Int = 10, defaultRefillRate: TimeInterval = 1.0) {
        self.defaultCapacity = defaultCapacity
        self.defaultRefillRate = defaultRefillRate
    }

    // MARK: - Public Methods

    /// Check if an action is allowed based on rate limits
    public func allowAction(_ action: String) -> Bool {
        if buckets[action] == nil {
            buckets[action] = Bucket(
                tokens: defaultCapacity,
                lastRefill: Date(),
                capacity: defaultCapacity,
                refillRate: defaultRefillRate
            )
        }

        return buckets[action]?.consume() ?? false
    }

    /// Reset rate limits for a specific action
    public func reset(action: String) {
        buckets[action] = Bucket(
            tokens: defaultCapacity,
            lastRefill: Date(),
            capacity: defaultCapacity,
            refillRate: defaultRefillRate
        )
    }

    /// Reset all rate limits
    public func resetAll() {
        buckets.removeAll()
    }

    /// Get remaining tokens for an action
    /// - Parameter action: The action identifier
    /// - Returns: Number of remaining tokens
    public func getRemainingTokens(_ action: String) -> Int {
        guard var bucket = buckets[action] else {
            // Return default capacity if bucket doesn't exist
            return buckets["default"]?.capacity ?? defaultCapacity
        }
        bucket.refill()
        return bucket.tokens
    }

    /// Configure rate limits for a specific action
    /// - Parameters:
    ///   - action: The action identifier
    ///   - capacity: Token bucket capacity
    ///   - refillRate: Seconds per token refill
    public func configure(action: String, capacity: Int, refillRate: TimeInterval) {
        buckets[action] = Bucket(
            tokens: capacity,
            lastRefill: Date(),
            capacity: capacity,
            refillRate: refillRate
        )
    }
}
