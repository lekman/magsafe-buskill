//
//  MockAuthenticationContextFactory.swift
//  MagSafeGuardTests
//
//  Created on 2025-07-26.
//
//  Shared mock factory for authentication context
//

import Foundation
@testable import MagSafeGuard

/// Mock factory for creating mock authentication contexts
class MockAuthenticationContextFactory: AuthenticationContextFactoryProtocol {
    private let context: MockAuthenticationContext
    
    init(mockContext: MockAuthenticationContext) {
        self.context = mockContext
    }
    
    func createContext() -> AuthenticationContextProtocol {
        return context
    }
}