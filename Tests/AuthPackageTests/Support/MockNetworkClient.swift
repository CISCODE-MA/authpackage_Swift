import Foundation
@testable import AuthPackage

final class MockNetworkClient: NetworkClient {
    struct Captured {
        let baseURL: URL
        let path: String
        let method: HTTPMethod
        let headers: [String:String]
        let body: [String:Any]?
    }
    var last: Captured?
    var responder: ((URL, String, HTTPMethod, [String:String], [String:Any]?) throws -> Any)?

    func send<T: Decodable>(
        baseURL: URL,
        path: String,
        method: HTTPMethod,
        headers: [String : String],
        body: [String : Any]?
    ) async throws -> T {
        last = .init(baseURL: baseURL, path: path, method: method, headers: headers, body: body)
        guard let responder = responder else { throw APIError.unknown }
        let obj = try responder(baseURL, path, method, headers, body)
        let data: Data
        if JSONSerialization.isValidJSONObject(obj) {
            data = try JSONSerialization.data(withJSONObject: obj, options: [])
        } else if let s = obj as? String {
            data = Data(s.utf8)
        } else if let d = obj as? Data {
            data = d
        } else {
            throw APIError.unknown
        }
        let dec = JSONDecoder()
        return try dec.decode(T.self, from: data)
    }
}
