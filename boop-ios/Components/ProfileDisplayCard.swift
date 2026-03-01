//
//  ProfileDisplayCard.swift
//  boop-ios
//

import SwiftUI

struct ProfileDisplayCard: View {
    let displayName: String
    let birthday: Date?
    let bio: String?
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Display Name
            Text(displayName)
                .font(.heading1)
                .foregroundColor(.staticWhite)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // Birthday
            if let birthday = birthday {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "birthday.cake")
                        .foregroundColor(.staticWhite)
                    Text(birthday.formatted(.dateTime.month().day()))
                        .font(.subtitle)
                        .foregroundColor(.staticWhite)
                }
            }
            
            // Bio
            if let bio = bio, !bio.isEmpty {
                Text(bio)
                    .foregroundColor(.staticWhite)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(.vertical, Spacing.lg)
    }
}

#Preview {
    ProfileDisplayCard(
        displayName: "Jane Doe",
        birthday: Date(),
        bio: "Coffee enthusiast and part-time adventurer"
    )
    .pageBackground()
}
