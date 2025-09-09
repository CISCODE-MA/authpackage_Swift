import Foundation

@MainActor
public final class ResetPasswordViewModel: ObservableObject {
    private let client: AuthClienting

    @Published public var token: String = ""
    @Published public var newPassword: String = ""

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    @Published public private(set) var didReset: Bool = false

    public init(client: AuthClienting) {
        self.client = client
    }

    public func submit() async {
        errorMessage = nil
        didReset = false
        guard !token.isEmpty else {
            errorMessage = "Token required."
            return
        }
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.resetPassword(
                token: token.trimmingCharacters(in: .whitespacesAndNewlines),
                newPassword: newPassword
            )
            didReset = true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Could not reset password."
        }
    }
}
