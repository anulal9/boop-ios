//
//  ContactDetailView.swift
//  boop-ios
//

import SwiftUI
import SwiftData

struct ContactDetailView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: Spacing.lg) {
                        // Avatar
                        if let avatarData = contact.avatarData,
                           let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
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
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Display Name
                        Text(contact.displayName)
                            .heading1Style()
                            .foregroundColor(.white)
                        
                        // Birthday
                        if let birthday = contact.birthday {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "birthday.cake")
                                    .foregroundColor(.accentPrimary)
                                Text(birthday.formatted(.dateTime.month().day()))
                                    .subtitleStyle()
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Bio
                        if let bio = contact.bio, !bio.isEmpty {
                            Text(bio)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.top, Spacing.sm)
                        }
                    }
                    .padding(.vertical, Spacing.lg)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                // Interaction History Section
                Section {
                    NavigationLink {
                        BoopHistoryView(contact: contact)
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.accentPrimary)
                            Text("Boop History")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(contact.interactions.count)")
                                .subtitleStyle()
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .pageBackground()
    }
}

struct BoopHistoryView: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            List(contact.interactions.sorted(by: { $0.timestamp > $1.timestamp })) { interaction in
                BoopInteractionCard(interaction: interaction)
                    .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Boop History")
        .navigationBarTitleDisplayMode(.inline)
        .pageBackground()
    }
}

#Preview {
    let contact = Contact(
        uuid: UUID(),
        displayName: "Jane Doe",
        avatarData: nil,
        birthday: Date(),
        bio: "Coffee enthusiast and part-time adventurer"
    )
    
    ContactDetailView(contact: contact)
        .modelContainer(for: Contact.self, inMemory: true)
}
