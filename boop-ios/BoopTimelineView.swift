//
//  BoopTimelineView.swift
//  boop-ios
//
//  Timeline view showing all boop interactions with smart time-based headers
//

import SwiftUI
import SwiftData

struct BoopTimelineView: View {
    @EnvironmentObject var boopManager: BoopManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BoopInteraction.timestamp, order: .reverse)
    private var allInteractions: [BoopInteraction]
    @Query private var contacts: [Contact]
    @State private var showBoop = false
    @State private var currentBoopDisplayName: String = ""

    private let animationDuration: TimeInterval = 2

    // Relative date formatter with controlled granularity
    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    // Calculate header text for a given timestamp (relative to current time)
    private func headerText(for date: Date) -> String {
        let headerText = relativeDateFormatter.localizedString(for: date, relativeTo: Date())

        // Sanitize and check for granular time units
        let sanitized = headerText.trimmingCharacters(in: .whitespaces).lowercased()
        let words = sanitized.components(separatedBy: .whitespaces)

        // If it contains minutes or hours, group under "Today"
        if words.contains(where: { $0.contains("minute") || $0.contains("hour") }) {
            return "Today"
        }

        return headerText.capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    Text("Timeline")
                        .primaryTextStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                }.frame(height: ComponentSize.pageHeaderHeight)

                Spacer()

                LazyVStack(spacing: Spacing.md) {
                    ForEach(Array(allInteractions.enumerated()), id: \.element.id) { index, interaction in
                        // Show header if this is the first item or the header changed from previous
                        let currentHeader = headerText(for: interaction.timestamp)
                        let previousHeader = index > 0 ? headerText(for: allInteractions[index - 1].timestamp) : nil

                        if previousHeader != currentHeader {
                            Text(currentHeader)
                                .heading1Style()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.md)
                        }

                        NavigationLink {
                            Text(interaction.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        } label: {
                            BoopInteractionCard(interaction: interaction)
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .scrollContentBackground(Visibility.hidden)
            }
            .pageBackground()
            .overlay {
                if showBoop {
                    ZStack {
                        Color.backgroundPrimary.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: Spacing.xl) {
                            Text("Boop!")
                                .heading1Style()
                            Text(currentBoopDisplayName)
                                .heading2Style()
                        }
                        .cardStyle()
                        .padding(Spacing.lg)
                    }
                }
            }
            .animation(.easeInOut(duration: animationDuration), value: showBoop)
            .onChange(of: boopManager.latestBoopEvent) { _, newValue in
                // Only show animation if Timeline is the active tab
                guard let event = newValue, !showBoop else { return }
                handleNewBoop(event: event)
            }
        }
    }

    private func handleNewBoop(event: BoopEvent) {
        let boop = event.boop

        // Store display name for modal
        currentBoopDisplayName = boop.displayName

        // Persist to SwiftData
        let contactUUID = boop.senderUUID

        // Find or create contact
        let contact: Contact
        if let existingContact = contacts.first(where: { $0.uuid == contactUUID }) {
            contact = existingContact
        } else {
            // Create new contact
            contact = Contact(uuid: contactUUID, displayName: boop.displayName)
            modelContext.insert(contact)
        }

        // Create interaction with contact relationship
        let newInteraction = BoopInteraction(
            title: boop.displayName,
            location: "temp - todo",
            timestamp: event.timestamp,
            contact: contact  // Set relationship
        )
        modelContext.insert(newInteraction)  // Insert as top-level entity
        contact.interactions.append(newInteraction)  // Also add to contact's array

        // Show modal (only if Timeline view is visible)
        showBoop = true

        // Hide modal after animation duration (but don't dismiss view)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showBoop = false
        }
    }
}

#Preview("TimelinePage") {
    BoopTimelineView()
        .modelContainer(for: [Contact.self, UserProfile.self, BoopInteraction.self])
        .environmentObject(BoopManager())
}
