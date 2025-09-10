//
//  TokenStore.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 08/09/2025.
//

import Foundation

public protocol TokenStore {
    func save(_ tokens: Tokens) throws
    func load() throws -> Tokens?
    func clear() throws
}

public final class InMemoryTokenStore: TokenStore {
    private var box: Tokens?
    public init() {}
    public func save(_ tokens: Tokens) throws { box = tokens }
    public func load() throws -> Tokens? { box }
    public func clear() throws { box = nil }
}
