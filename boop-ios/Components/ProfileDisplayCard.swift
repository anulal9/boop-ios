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
                .heading1Style()
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // Birthday
            if let birthday = birthday {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "birthday.cake")
                        .foregroundColor(.accentPrimary)
                    Text(birthday.formatted(.dateTime.month().day()))
                        .subtitleStyle()
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Bio
            if let bio = bio, !bio.isEmpty {
                Text(bio)
                    .foregroundColor(.textPrimary)
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
