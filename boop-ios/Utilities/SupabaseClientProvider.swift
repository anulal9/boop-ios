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
    static let urlString: String = "https://rhtitjcedoirqidrqvin.supabase.co" // e.g. https://xyzcompany.supabase.co
    static let anonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJodGl0amNlZG9pcnFpZHJxdmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2MDY3MzQsImV4cCI6MjA4MjE4MjczNH0.q0Sta7PNsrJrYT-4-68MKEWQVjLholEJjCm7C6nClvA"
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
