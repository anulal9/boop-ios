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
        Task {
            // Safe to read UserDefaults now - directory is guaranteed to exist
            if let cachedUser = await GetFromUserDefaultsString(key: appleIDKey) {
                self.userID = cachedUser
                let isComplete = await GetFromUserDefaultsBool(key: profileCompleteKey)
                authState = isComplete ? .completed : .profileSetup
            }
        }
    }


    func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        Task {
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
    
    }

    private func handleSuccess(credential: ASAuthorizationAppleIDCredential) {
        UpdateUserDefaults(value: credential.user, key: appleIDKey)
        self.userID = credential.user
        if let firstName = credential.fullName?.givenName {
            UpdateUserDefaults(value: firstName, key: fullNameKey)
        }
        authState = .profileSetup
    }

    private func handleFailure(_ message: String) {
        authState = .failed(message)
    }

    func completeProfileSetup() {
        UpdateUserDefaults(value: true, key: profileCompleteKey)
        authState = .completed
    }
    
    private func GetFromUserDefaultsString(key: String) async -> String? {
            UserDefaults.standard.string(forKey: key)
    }
    
    private func GetFromUserDefaultsBool(key: String) async -> Bool {
            UserDefaults.standard.bool(forKey: key)
    }
    
    private func UpdateUserDefaults(value: Bool, key: String)
    {
        Task {
            UserDefaults.standard.set(value, forKey: key)
        }
    }

    private func UpdateUserDefaults(value: String, key: String)
    {
        Task {
            UserDefaults.standard.set(value, forKey: key)
        }
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
