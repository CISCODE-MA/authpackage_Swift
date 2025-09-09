#if canImport(SwiftUI)
import Foundation
import AuthPackage

@MainActor
public final class OTPViewModel: ObservableObject {
    private let client: AuthClientProtocol
    private let identifier: String

    @Published public var otp: String = ""
    @Published public var isLoading = false
    @Published public var error: String?
    @Published public var user: User?

    public init(client: AuthClientProtocol, identifier: String) {
        self.client = client
        self.identifier = identifier
    }

    public func verify() async {
        isLoading = true; defer { isLoading = false }
        do {
            user = try await client.verifyOTP(identifier: identifier, otp: otp)
        } catch {
            self.error = String(describing: error)
        }
    }
}
#endif
