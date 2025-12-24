import Foundation
import AuthenticationServices
import CryptoKit

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
    private var currentNonce: String?

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
        print("📱 handleCompletion called")
        Task {
            switch result {
            case .success(let authorization):
                print("✅ Authorization successful")
                switch authorization.credential {
                case let credential as ASAuthorizationAppleIDCredential:
                    print("🍎 Got Apple ID credential")
                    await handleSuccess(credential: credential)
                default:
                    print("❌ Unsupported credential type")
                    handleFailure("Unsupported credential")
                }
            case .failure(let error):
                print("❌ Authorization failed: \(error.localizedDescription)")
                handleFailure(error.localizedDescription)
            }
        }
    
    }

    private func handleSuccess(credential: ASAuthorizationAppleIDCredential) async {
        print("🔐 handleSuccess called with user: \(credential.user)")
        
        await DataStore.shared.setAppleUserID(credential.user)
        print("💾 Saved Apple user ID to DataStore")
        
        // Attempt Supabase sign-in using Apple identity token + nonce
        #if canImport(Supabase)
        if let tokenData = credential.identityToken,
           let tokenStr = String(data: tokenData, encoding: .utf8) {
            let nonce = currentNonce ?? ""
            print("🔑 Attempting Supabase sign-in...")
            do {
                try await SupabaseClientProvider.shared.signInWithApple(idToken: tokenStr, nonce: nonce)
                print("✅ Supabase sign-in successful")
            } catch {
                // Non-fatal: fall back to local state
                print("⚠️ Supabase Apple sign-in failed: \(error)")
            }
        } else {
            print("⚠️ Missing Apple identityToken; skipping Supabase sign-in")
        }
        #endif
        
        self.userID = credential.user
        print("🎯 Setting authState to .profileSetup")
        authState = .profileSetup
        print("✅ Auth state updated to: \(authState)")
    }

    private func handleFailure(_ message: String) {
        print("💥 handleFailure called with: \(message)")
        authState = .failed(message)
        print("📊 Auth state set to: \(authState)")
    }

    func completeProfileSetup(userProfile: UserProfile) {
        Task {
            await DataStore.shared.setUserProfile(userProfile)
            await DataStore.shared.setProfileComplete(true)
        }
        authState = .completed
    }

    // MARK: - Apple Sign-In helpers
    /// Initiate Sign in with Apple using the delegate pattern
    func signInWithApple() {
        print("🚀 signInWithApple() called - starting authorization")
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        authState = .authorizing
        print("📊 Auth state set to: \(authState)")
        
        authorizationController.performRequests()
        print("✅ Authorization request sent")
    }
    
    /// Call this from SignInWithAppleButton onRequest
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("🔧 configureAppleRequest called")
        authState = .authorizing
        print("📊 Auth state set to: \\(authState)")
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        print("✅ Request configured with nonce")
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            result.append(charset[Int(random) % charset.count])
            remainingLength -= 1
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ Delegate: didCompleteWithAuthorization called")
        Task {
            switch authorization.credential {
                case let credential as ASAuthorizationAppleIDCredential:
                    print("🍎 Delegate: Got Apple ID credential")
                    await handleSuccess(credential: credential)
                default:
                    print("❌ Delegate: Unsupported credential type")
                    handleFailure("Unsupported credential")
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Delegate: didCompleteWithError called: \(error.localizedDescription)")
        handleFailure(error.localizedDescription)
    }
}

extension AppleAuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("⚠️ Could not find key window, using first available window")
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
        return window
    }
}
