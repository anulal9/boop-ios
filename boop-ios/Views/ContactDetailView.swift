//
//  ContactDetailView.swift
//  boop-ios
//

import SwiftUI
import SwiftData

/// Lightweight Hashable route used to push BoopHistoryView
/// without relying on an isPresented binding that stays true
/// while navigating deeper in the stack.
struct BoopHistoryRoute: Hashable {
    let contact: Contact
}

struct ContactDetailView: View {
    let contact: Contact
    @EnvironmentObject private var boopManager: BoopManager

    private let reminderOptions: [(label: String, minutes: Int?)] = [
        ("Default (\(NotificationScheduler.defaultReminderIntervalMinutes) min)", nil),
        ("1 minute", 1),
        ("1 hour", 60),
        ("1 week", 7 * 24 * 60),
        ("2 weeks", 14 * 24 * 60),
        ("1 month", 30 * 24 * 60),
    ]

    var body: some View {
        ZStack {
            AnimatedMeshGradient(
                colors: contact.gradientColors,
                animationStyle: .horizontalWave,
                duration: 3.0
            )
            .ignoresSafeArea()

            Form {
                Section {
                    ProfileDisplayCard(
                        displayName: contact.displayName,
                        birthday: contact.birthday,
                        bio: contact.bio,
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Reminder frequency
                Section {
                    Picker("Remind me every", selection: Binding(
                        get: { contact.reminderIntervalMinutes },
                        set: { newValue in
                            ContactRepository.shared.updateReminderInterval(contact, intervalMinutes: newValue)
                            boopManager.rescheduleReminder(for: contact)
                        }
                    )) {
                        ForEach(reminderOptions, id: \.label) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }
                    .pickerStyle(.menu)
                    .foregroundColor(.staticWhite)
                }
                .listRowBackground(Color.clear)

                // Interaction History Section
                Section {
                    NavigationLink(value: BoopHistoryRoute(contact: contact)) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.staticWhite)
                            Text("Boop History")
                                .foregroundColor(.staticWhite)
                            Spacer()
                            Text("\(contact.interactions.count)")
                                .font(.subtitle)
                                .foregroundColor(.staticWhite)
                        }
                        .padding(.vertical, Spacing.sm)
                    }
                }
                .listRowBackground(Color.clear)
                .tint(.staticWhite)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(contact.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BoopHistoryView: View {
    let contact: Contact

    var body: some View {
        ScrollView {
            BoopInteractionTimelineBody(
                interactions: contact.interactions.sorted(by: { $0.timestamp > $1.timestamp })
            )
        }
        .navigationTitle(contact.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .pageBackground()
    }
}

#Preview {
    let contact = Contact(
        uuid: UUID(),
        displayName: "Jane Doe",
        birthday: Date(),
        bio: "Coffee enthusiast and part-time adventurer"
    )
    
    ContactDetailView(contact: contact)
        .modelContainer(for: Contact.self, inMemory: true)
}
