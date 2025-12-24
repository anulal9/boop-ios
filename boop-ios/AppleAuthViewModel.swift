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

    override init() {
        super.init()
        Task {
            // Read from DataStore (cache is warmed up by this point)
            if let cachedUser = await DataStore.shared.getAppleUserID() {
                self.userID = cachedUser
                let isComplete = await DataStore.shared.isProfileComplete()
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
        Task {
            await DataStore.shared.setAppleUserID(credential.user)
        }
        self.userID = credential.user
        authState = .profileSetup
    }

    private func handleFailure(_ message: String) {
        authState = .failed(message)
    }

    func completeProfileSetup(userProfile: UserProfile) {
        Task {
            await DataStore.shared.setUserProfile(userProfile)
            await DataStore.shared.setProfileComplete(true)
        }
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
