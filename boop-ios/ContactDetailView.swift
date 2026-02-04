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
            ZStack {
                // Use contact's gradient colors as background
                AnimatedMeshGradient(
                    colors: contact.gradientColors,
                    animationStyle: .horizontalWave,
                    duration: 3.0
                )
                .ignoresSafeArea()
                
                Form {
                    Section {
                        ProfileDisplayCard(
                            avatarImage: contact.avatarData.flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) },
                            displayName: contact.displayName,
                            birthday: contact.birthday,
                            bio: contact.bio
                        )
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
            }
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
