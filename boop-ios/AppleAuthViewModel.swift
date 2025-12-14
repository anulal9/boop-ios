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
    private let userNameKey = "boopUserName"
    private let firstNameKey = "boopFirstName"
    private let lastNameKey = "boopLastName"
    private let birthDateKey = "boopBirthday"
    private let isAdultKey = "boopIsAdult"

    override init() {
        super.init()
        Task {
            // Safe to read UserDefaults now - directory is guaranteed to exist
            if let cachedUser = await UserDefaultsUtility.getString(forKey: appleIDKey) {
                self.userID = cachedUser
                let isComplete = await UserDefaultsUtility.getBool(forKey: profileCompleteKey)
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
        UserDefaultsUtility.set(credential.user, forKey: appleIDKey)
        self.userID = credential.user
        authState = .profileSetup
    }

    private func handleFailure(_ message: String) {
        authState = .failed(message)
    }

    func completeProfileSetup(userProfile: UserProfile) {
        UserDefaultsUtility.set(true, forKey: profileCompleteKey)
        authState = .completed
    }
    
    private func saveUserToStore(userProfile: UserProfile) {
        Task {
            await UserDefaultsUtility.setAsync(userProfile.firstName, forKey: firstNameKey)
            await UserDefaultsUtility.setAsync(userProfile.lastName, forKey: lastNameKey)
            await UserDefaultsUtility.setAsync(userProfile.displayName, forKey: userNameKey)
            await UserDefaultsUtility.setAsync(userProfile.dateOfBirth, forKey: birthDateKey)
            await UserDefaultsUtility.setAsync(userProfile.isAdult, forKey: isAdultKey)
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
