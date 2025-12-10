import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class AppleAuthViewModel: NSObject, ObservableObject {
    enum AuthState: Equatable {
        case signedOut
        case authorizing
        case signedIn(userID: String)
        case failed(String)
    }

    @Published private(set) var authState: AuthState = .signedOut

    private let userDefaultsKey = "appleUserID"

    override init() {
        super.init()
        if let cachedUser = UserDefaults.standard.string(forKey: userDefaultsKey) {
            authState = .signedIn(userID: cachedUser)
        }
    }

    func signIn() {
        authState = .authorizing
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            switch authorization.credential {
            case let credential as ASAuthorizationAppleIDCredential:
                handleSuccess(userID: credential.user)
            default:
                handleFailure("Unsupported credential")
            }
        case .failure(let error):
            handleFailure(error.localizedDescription)
        }
    }

    private func handleSuccess(userID: String) {
        UserDefaults.standard.set(userID, forKey: userDefaultsKey)
        authState = .signedIn(userID: userID)
    }

    private func handleFailure(_ message: String) {
        authState = .failed(message)
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            handleSuccess(userID: credential.user)
        default:
            handleFailure("Unsupported credential")
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleFailure(error.localizedDescription)
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow()
    }
}
