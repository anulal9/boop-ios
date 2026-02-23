//
//  ProfileDisplayCard.swift
//  boop-ios
//

import SwiftUI

struct ProfileDisplayCard: View {
    let avatarImage: Image?
    let displayName: String
    let birthday: Date?
    let bio: String?
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Avatar
            if let avatarImage = avatarImage {
                avatarImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.textMuted)
                    .frame(maxWidth: .infinity)
            }
            
            // Display Name
            Text(displayName)
                .heading1Style()
                .foregroundColor(.textPrimary)
            
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
        avatarImage: nil,
        displayName: "Jane Doe",
        birthday: Date(),
        bio: "Coffee enthusiast and part-time adventurer"
    )
    .pageBackground()
}
