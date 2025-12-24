//
//  SupabaseClientProvider.swift
//  boop-ios
//
//  Created by GitHub Copilot on 12/24/25.
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct SupabaseConfig {
    // TODO: Set your Supabase URL and anon key
    static let urlString: String = "ASK FOR THIS" // e.g. https://xyzcompany.supabase.co
    static let anonKey: String = "ASK FOR THIS"
}


final class SupabaseClientProvider {
    static let shared = SupabaseClientProvider()

    #if canImport(Supabase)
    let client: SupabaseClient?
    #endif

    private init() {
        #if canImport(Supabase)
        guard let url = URL(string: SupabaseConfig.urlString) else {
            client = nil
            print("⚠️ Invalid Supabase URL")
            return
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
        print("✅ Supabase client initialized")
        #endif
    }
}

#if canImport(Supabase)
extension SupabaseClientProvider {
    func signInWithApple(idToken: String, nonce: String) async throws {
        print("🔵 signInWithApple called")
        guard let client = client else {
            print("⚠️ Supabase client is nil, skipping sign-in")
            return
        }
        print("🔵 Client exists, attempting sign-in with Supabase...")
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        print("✅ Supabase signInWithIdToken completed")
    }

    func signOut() async throws {
        guard let client = client else {
            return
        }
        try await client.auth.signOut()
    }
}
#endif
