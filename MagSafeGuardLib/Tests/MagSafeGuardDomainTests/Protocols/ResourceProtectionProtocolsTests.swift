//
//  ResourceProtectionProtocolsTests.swift
//  MagSafeGuardDomainTests
//
//  Created on 2025-08-06.
//
//  Tests for ResourceProtectionProtocols configuration structs and models
//

import Foundation
import Testing
@testable import MagSafeGuardDomain

@Suite("ResourceProtectionProtocols Tests")
struct ResourceProtectionProtocolsTests {
    
    // MARK: - CircuitState Tests
    
    @Test("CircuitState raw values")
    func testCircuitStateRawValues() {
        #expect(CircuitState.closed.rawValue == "closed")
        #expect(CircuitState.open.rawValue == "open")
        #expect(CircuitState.halfOpen.rawValue == "halfOpen")
    }
    
    @Test("CircuitState is Codable")
    func testCircuitStateCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let states: [CircuitState] = [.closed, .open, .halfOpen]
        
        for state in states {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(CircuitState.self, from: data)
            #expect(decoded == state)
        }
    }
    
    // MARK: - ProtectionMetrics Tests
    
    @Test("ProtectionMetrics initialization")
    func testProtectionMetricsInit() {
        let date = Date()
        let metrics = ProtectionMetrics(
            totalAttempts: 100,
            successfulExecutions: 80,
            rateLimitedAttempts: 15,
            circuitBreakerRejections: 5,
            lastAttemptTime: date,
            successRate: 0.8
        )
        
        #expect(metrics.totalAttempts == 100)
        #expect(metrics.successfulExecutions == 80)
        #expect(metrics.rateLimitedAttempts == 15)
        #expect(metrics.circuitBreakerRejections == 5)
        #expect(metrics.lastAttemptTime == date)
        #expect(metrics.successRate == 0.8)
    }
    
    @Test("ProtectionMetrics.empty")
    func testProtectionMetricsEmpty() {
        let metrics = ProtectionMetrics.empty
        
        #expect(metrics.totalAttempts == 0)
        #expect(metrics.successfulExecutions == 0)
        #expect(metrics.rateLimitedAttempts == 0)
        #expect(metrics.circuitBreakerRejections == 0)
        #expect(metrics.lastAttemptTime == nil)
        #expect(metrics.successRate == 0.0)
    }
    
    @Test("ProtectionMetrics Equatable")
    func testProtectionMetricsEquatable() {
        let date = Date()
        let metrics1 = ProtectionMetrics(
            totalAttempts: 50,
            successfulExecutions: 40,
            rateLimitedAttempts: 5,
            circuitBreakerRejections: 5,
            lastAttemptTime: date,
            successRate: 0.8
        )
        
        let metrics2 = ProtectionMetrics(
            totalAttempts: 50,
            successfulExecutions: 40,
            rateLimitedAttempts: 5,
            circuitBreakerRejections: 5,
            lastAttemptTime: date,
            successRate: 0.8
        )
        
        let metrics3 = ProtectionMetrics(
            totalAttempts: 60,
            successfulExecutions: 40,
            rateLimitedAttempts: 5,
            circuitBreakerRejections: 5,
            lastAttemptTime: date,
            successRate: 0.8
        )
        
        #expect(metrics1 == metrics2)
        #expect(metrics1 != metrics3)
    }
    
    // MARK: - RateLimiterConfig Tests
    
    @Test("RateLimiterConfig initialization")
    func testRateLimiterConfigInit() {
        let config = RateLimiterConfig(
            lockScreen: (capacity: 10, refillRate: 1.0),
            playAlarm: (capacity: 5, refillRate: 2.0),
            forceLogout: (capacity: 3, refillRate: 5.0),
            shutdown: (capacity: 2, refillRate: 10.0),
            executeScript: (capacity: 4, refillRate: 3.0)
        )
        
        #expect(config.lockScreen.capacity == 10)
        #expect(config.lockScreen.refillRate == 1.0)
        #expect(config.playAlarm.capacity == 5)
        #expect(config.playAlarm.refillRate == 2.0)
        #expect(config.forceLogout.capacity == 3)
        #expect(config.forceLogout.refillRate == 5.0)
        #expect(config.shutdown.capacity == 2)
        #expect(config.shutdown.refillRate == 10.0)
        #expect(config.executeScript.capacity == 4)
        #expect(config.executeScript.refillRate == 3.0)
    }
    
    @Test("RateLimiterConfig.defaultConfig")
    func testRateLimiterConfigDefault() {
        let config = RateLimiterConfig.defaultConfig
        
        #expect(config.lockScreen.capacity == 5)
        #expect(config.lockScreen.refillRate == 2.0)
        #expect(config.playAlarm.capacity == 3)
        #expect(config.playAlarm.refillRate == 5.0)
        #expect(config.forceLogout.capacity == 2)
        #expect(config.forceLogout.refillRate == 30.0)
        #expect(config.shutdown.capacity == 1)
        #expect(config.shutdown.refillRate == 60.0)
        #expect(config.executeScript.capacity == 3)
        #expect(config.executeScript.refillRate == 10.0)
    }
    
    @Test("RateLimiterConfig.strict")
    func testRateLimiterConfigStrict() {
        let config = RateLimiterConfig.strict
        
        #expect(config.lockScreen.capacity == 3)
        #expect(config.lockScreen.refillRate == 5.0)
        #expect(config.playAlarm.capacity == 2)
        #expect(config.playAlarm.refillRate == 10.0)
        #expect(config.forceLogout.capacity == 1)
        #expect(config.forceLogout.refillRate == 60.0)
        #expect(config.shutdown.capacity == 1)
        #expect(config.shutdown.refillRate == 300.0)
        #expect(config.executeScript.capacity == 1)
        #expect(config.executeScript.refillRate == 30.0)
    }
    
    @Test("RateLimiterConfig.test")
    func testRateLimiterConfigTest() {
        let config = RateLimiterConfig.test
        
        #expect(config.lockScreen.capacity == 2)
        #expect(config.lockScreen.refillRate == 0.1)
        #expect(config.playAlarm.capacity == 2)
        #expect(config.playAlarm.refillRate == 0.1)
        #expect(config.forceLogout.capacity == 1)
        #expect(config.forceLogout.refillRate == 0.1)
        #expect(config.shutdown.capacity == 1)
        #expect(config.shutdown.refillRate == 0.1)
        #expect(config.executeScript.capacity == 2)
        #expect(config.executeScript.refillRate == 0.1)
    }
    
    // MARK: - CircuitBreakerConfig Tests
    
    @Test("CircuitBreakerConfig initialization")
    func testCircuitBreakerConfigInit() {
        let config = CircuitBreakerConfig(
            lockScreen: (failures: 5, successes: 3, timeout: 60.0),
            playAlarm: (failures: 4, successes: 2, timeout: 45.0),
            forceLogout: (failures: 3, successes: 2, timeout: 90.0),
            shutdown: (failures: 2, successes: 1, timeout: 180.0),
            executeScript: (failures: 3, successes: 3, timeout: 30.0)
        )
        
        #expect(config.lockScreen.failures == 5)
        #expect(config.lockScreen.successes == 3)
        #expect(config.lockScreen.timeout == 60.0)
        #expect(config.playAlarm.failures == 4)
        #expect(config.playAlarm.successes == 2)
        #expect(config.playAlarm.timeout == 45.0)
        #expect(config.forceLogout.failures == 3)
        #expect(config.forceLogout.successes == 2)
        #expect(config.forceLogout.timeout == 90.0)
        #expect(config.shutdown.failures == 2)
        #expect(config.shutdown.successes == 1)
        #expect(config.shutdown.timeout == 180.0)
        #expect(config.executeScript.failures == 3)
        #expect(config.executeScript.successes == 3)
        #expect(config.executeScript.timeout == 30.0)
    }
    
    @Test("CircuitBreakerConfig.defaultConfig")
    func testCircuitBreakerConfigDefault() {
        let config = CircuitBreakerConfig.defaultConfig
        
        #expect(config.lockScreen.failures == 3)
        #expect(config.lockScreen.successes == 2)
        #expect(config.lockScreen.timeout == 30.0)
        #expect(config.playAlarm.failures == 3)
        #expect(config.playAlarm.successes == 2)
        #expect(config.playAlarm.timeout == 30.0)
        #expect(config.forceLogout.failures == 2)
        #expect(config.forceLogout.successes == 1)
        #expect(config.forceLogout.timeout == 60.0)
        #expect(config.shutdown.failures == 2)
        #expect(config.shutdown.successes == 1)
        #expect(config.shutdown.timeout == 120.0)
        #expect(config.executeScript.failures == 2)
        #expect(config.executeScript.successes == 2)
        #expect(config.executeScript.timeout == 60.0)
    }
    
    @Test("CircuitBreakerConfig.resilient")
    func testCircuitBreakerConfigResilient() {
        let config = CircuitBreakerConfig.resilient
        
        #expect(config.lockScreen.failures == 5)
        #expect(config.lockScreen.successes == 3)
        #expect(config.lockScreen.timeout == 20.0)
        #expect(config.playAlarm.failures == 5)
        #expect(config.playAlarm.successes == 3)
        #expect(config.playAlarm.timeout == 20.0)
        #expect(config.forceLogout.failures == 3)
        #expect(config.forceLogout.successes == 2)
        #expect(config.forceLogout.timeout == 45.0)
        #expect(config.shutdown.failures == 3)
        #expect(config.shutdown.successes == 2)
        #expect(config.shutdown.timeout == 90.0)
        #expect(config.executeScript.failures == 3)
        #expect(config.executeScript.successes == 2)
        #expect(config.executeScript.timeout == 45.0)
    }
    
    @Test("CircuitBreakerConfig.test")
    func testCircuitBreakerConfigTest() {
        let config = CircuitBreakerConfig.test
        
        #expect(config.lockScreen.failures == 2)
        #expect(config.lockScreen.successes == 1)
        #expect(config.lockScreen.timeout == 0.2)
        #expect(config.playAlarm.failures == 2)
        #expect(config.playAlarm.successes == 1)
        #expect(config.playAlarm.timeout == 0.2)
        #expect(config.forceLogout.failures == 1)
        #expect(config.forceLogout.successes == 1)
        #expect(config.forceLogout.timeout == 0.2)
        #expect(config.shutdown.failures == 1)
        #expect(config.shutdown.successes == 1)
        #expect(config.shutdown.timeout == 0.2)
        #expect(config.executeScript.failures == 2)
        #expect(config.executeScript.successes == 1)
        #expect(config.executeScript.timeout == 0.2)
    }
    
    // MARK: - ResourceProtectorConfig Tests
    
    @Test("ResourceProtectorConfig initialization")
    func testResourceProtectorConfigInit() {
        let config = ResourceProtectorConfig(
            rateLimiter: .strict,
            circuitBreaker: .resilient,
            enableMetrics: false,
            enableLogging: false
        )
        
        #expect(config.rateLimiter.lockScreen.capacity == RateLimiterConfig.strict.lockScreen.capacity)
        #expect(config.circuitBreaker.lockScreen.failures == CircuitBreakerConfig.resilient.lockScreen.failures)
        #expect(config.enableMetrics == false)
        #expect(config.enableLogging == false)
    }
    
    @Test("ResourceProtectorConfig.defaultConfig")
    func testResourceProtectorConfigDefault() {
        let config = ResourceProtectorConfig.defaultConfig
        
        #expect(config.rateLimiter.lockScreen.capacity == RateLimiterConfig.defaultConfig.lockScreen.capacity)
        #expect(config.circuitBreaker.lockScreen.failures == CircuitBreakerConfig.defaultConfig.lockScreen.failures)
        #expect(config.enableMetrics == true)
        #expect(config.enableLogging == true)
    }
    
    @Test("ResourceProtectorConfig.strict")
    func testResourceProtectorConfigStrict() {
        let config = ResourceProtectorConfig.strict
        
        #expect(config.rateLimiter.lockScreen.capacity == RateLimiterConfig.strict.lockScreen.capacity)
        #expect(config.circuitBreaker.lockScreen.failures == CircuitBreakerConfig.resilient.lockScreen.failures)
        #expect(config.enableMetrics == true)
        #expect(config.enableLogging == true)
    }
    
    @Test("ResourceProtectorConfig.test")
    func testResourceProtectorConfigTest() {
        let config = ResourceProtectorConfig.test
        
        #expect(config.rateLimiter.lockScreen.capacity == RateLimiterConfig.test.lockScreen.capacity)
        #expect(config.circuitBreaker.lockScreen.failures == CircuitBreakerConfig.test.lockScreen.failures)
        #expect(config.enableMetrics == true)
        #expect(config.enableLogging == false)
    }
}