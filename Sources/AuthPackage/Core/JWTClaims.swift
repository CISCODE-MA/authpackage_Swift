//
//  JWTClaims.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

import Foundation

public struct JWTClaims: Codable, Equatable, Sendable {
    public let sub: String?
    public let email: String?
    public let tenantId: String?
    public let roles: [String]?
    public let permissions: [String]?
    public let exp: Double?
    public let iat: Double?
    public let raw: [String: StringOrNumber]?
}

public enum StringOrNumber: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    public init(from d: Decoder) throws {
        let c = try d.singleValueContainer()
        if let s = try? c.decode(String.self) {
            self = .string(s)
            return
        }
        if let n = try? c.decode(Double.self) {
            self = .number(n)
            return
        }
        throw DecodingError.typeMismatch(
            Self.self,
            .init(
                codingPath: d.codingPath,
                debugDescription: "Not string or number"
            )
        )
    }
    public func encode(to e: Encoder) throws {
        var c = e.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        }
    }
}

public enum JWTDecoder {
    public static func decode(_ token: String) -> JWTClaims? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        func b64(_ s: Substring) -> Data? {
            var x = s.replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let pad = 4 - x.count % 4
            if pad < 4 { x += String(repeating: "=", count: pad) }
            return Data(base64Encoded: x)
        }
        guard let data = b64(parts[1]),
            let dict = try? JSONDecoder().decode(
                [String: StringOrNumber].self,
                from: data
            )
        else { return nil }
        func str(_ k: String) -> String? {
            if case .string(let v)? = dict[k] { return v } else { return nil }
        }
        func num(_ k: String) -> Double? {
            switch dict[k] {
            case .number(let d)?: return d
            case .string(let s)?: return Double(s)
            default: return nil
            }
        }
        return JWTClaims(
            sub: str("sub"),
            email: str("email"),
            tenantId: str("tenantId"),
            roles: nil,
            permissions: nil,
            exp: num("exp"),
            iat: num("iat"),
            raw: dict
        )
    }
}
