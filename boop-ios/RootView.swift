import SwiftUI
import AuthenticationServices

struct RootView: View {
    @StateObject private var authViewModel = AppleAuthViewModel()

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .signedIn:
                BoopView()
            case .authorizing:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Signing in...")
                }
            case .failed(let message):
                VStack(spacing: 16) {
                    Text("Sign in failed")
                        .font(.headline)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    signInButton
                }
                .padding()
            case .signedOut:
                VStack(spacing: 24) {
                    Text("Welcome to Boop")
                        .font(.title2)
                        .fontWeight(.semibold)
                    signInButton
                }
                .padding()
            }
        }
    }

    private var signInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            authViewModel.handleCompletion(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(8)
    }
}

#Preview {
    RootView()
}
