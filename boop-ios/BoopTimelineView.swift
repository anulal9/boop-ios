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

    // Time bucket key for grouping - uses timestamp rounded to appropriate granularity
    struct TimeBucket: Hashable {
        let timestamp: Date
        let displayText: String
        let sortOrder: Date  // For sorting sections

        init(for date: Date) {
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.day], from: date, to: now)
            let daysAgo = components.day ?? 0

            // Determine granularity based on age
            if daysAgo <= 7 {
                // Recent: daily buckets
                self.timestamp = calendar.startOfDay(for: date)
                self.sortOrder = self.timestamp
            } else if daysAgo <= 30 {
                // Mid-range: weekly buckets
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
                self.timestamp = weekStart
                self.sortOrder = weekStart
            } else {
                // Older: monthly buckets
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                self.timestamp = monthStart
                self.sortOrder = monthStart
            }

            // Use Swift's built-in relative date formatter
            self.displayText = self.timestamp.formatted(.relative(presentation: .named))
                .capitalized  // "yesterday" -> "Yesterday"
        }
    }

    // Group interactions by time bucket
    private var groupedInteractions: [(bucket: TimeBucket, interactions: [BoopInteraction])] {
        let grouped = Dictionary(grouping: allInteractions) { interaction in
            TimeBucket(for: interaction.timestamp)
        }

        // Sort by most recent first
        return grouped.map { ($0.key, $0.value) }
            .sorted { $0.bucket.sortOrder > $1.bucket.sortOrder }
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

                LazyVStack(spacing: 0) {
                    ForEach(groupedInteractions, id: \.bucket) { group in
                        // Section header
                        Text(group.bucket.displayText)
                            .heading1Style()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.md)

                        // Interactions for this time bucket
                        ForEach(group.interactions) { interaction in
                            NavigationLink {
                                Text(interaction.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            } label: {
                                BoopInteractionCard(interaction: interaction)
                            }
                        }
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
            .onChange(of: boopManager.latestBoopEvent) { oldValue, newValue in
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
