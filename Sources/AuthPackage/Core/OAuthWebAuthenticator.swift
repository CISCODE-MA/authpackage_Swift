//
//  OAuthWebAuthenticator.swift
//  AuthPackage
//
//  Created by Zaid MOUMNI on 10/09/2025.
//

//import AuthenticationServices
//import Foundation
//
//actor OAuthWebAuthenticator: NSObject {
//    func authenticateMicrosoft(config: AuthConfiguration) async throws
//        -> SocialCredential
//    {
//        guard let ms = config.providers.microsoft, ms.enabled else {
//            throw APIError.unauthorized
//        }
//        // Build backend authorize URL; backend will talk to Microsoft securely.
//        var comps = URLComponents(
//            url: config.baseURL,
//            resolvingAgainstBaseURL: false
//        )!
//        comps.path = Endpoints.oauthAuthorize
//        comps.queryItems = [
//            .init(name: "provider", value: "microsoft"),
//            .init(name: "tenant", value: ms.tenant),
//            .init(name: "redirect_uri", value: ms.redirectURI),
//            .init(name: "client_id", value: ms.clientID),
//        ]
//        guard let url = comps.url else { throw APIError.invalidURL }
//
//        let callbackScheme = ms.redirectScheme
//
//        return try await withCheckedThrowingContinuation { cont in
//            let session = ASWebAuthenticationSession(
//                url: url,
//                callbackURLScheme: callbackScheme
//            ) { callbackURL, error in
//                if let error {
//                    return cont.resume(
//                        throwing: APIError.network(String(describing: error))
//                    )
//                }
//                guard let callbackURL else {
//                    return cont.resume(throwing: APIError.unknown)
//                }
//
//                let parts = URLComponents(
//                    url: callbackURL,
//                    resolvingAgainstBaseURL: false
//                )
//                let idToken = parts?.queryItems?.first(where: {
//                    $0.name == "id_token"
//                })?.value
//                let accessToken = parts?.queryItems?.first(where: {
//                    $0.name == "access_token"
//                })?.value
//                if idToken == nil && accessToken == nil {
//                    return cont.resume(throwing: APIError.unauthorized)
//                }
//
//                cont.resume(
//                    returning: SocialCredential(
//                        provider: .microsoft,
//                        idToken: idToken,
//                        accessToken: accessToken
//                    )
//                )
//            }
//            session.prefersEphemeralWebBrowserSession = true
//            session.presentationContextProvider = self
//            _ = session.start()
//        }
//    }
//}
//
//extension OAuthWebAuthenticator: ASWebAuthenticationPresentationContextProviding
//{
//    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession)
//        -> ASPresentationAnchor
//    {
//        ASPresentationAnchor()
//    }
//}
