import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class AppleAuthViewModel: NSObject, ObservableObject {
    enum AuthState: Equatable {
        case signedOut
        case authorizing
        case signedIn(userID: String)
        case profileSetup
        case completed
        case failed(String)
    }

    @Published private(set) var authState: AuthState = .signedOut
    @Published private(set) var userID: String?

    private let appleIDKey = "appleUserID"
    private let profileCompleteKey = "profileComplete"
    private let fullNameKey = "appleFullName"

    override init() {
        super.init()
        if let cachedUser = UserDefaults.standard.string(forKey: appleIDKey) {
            let isComplete = UserDefaults.standard.bool(forKey: profileCompleteKey)
            authState = isComplete ? .completed : .profileSetup
            self.userID = cachedUser
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
                handleSuccess(credential: credential)
            default:
                handleFailure("Unsupported credential")
            }
        case .failure(let error):
            handleFailure(error.localizedDescription)
        }
    }

    private func handleSuccess(credential: ASAuthorizationAppleIDCredential) {
        UserDefaults.standard.set(credential.user, forKey: appleIDKey)
        if let firstName = credential.fullName?.givenName {
            UserDefaults.standard.set(firstName, forKey:
                                        fullNameKey)
        }
        authState = .signedIn(userID: credential.user)
    }

    private func handleFailure(_ message: String) {
        authState = .failed(message)
    }

    func completeProfileSetup() {
        UserDefaults.standard.set(true, forKey: profileCompleteKey)
        authState = .completed
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            handleSuccess(credential: credential)
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
