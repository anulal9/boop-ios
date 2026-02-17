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
    @State private var showAddManualBoop = false
    @State private var currentBoopDisplayName: String = ""
    @State private var navigationPath = NavigationPath()
    @Binding var selectedInteractionID: UUID?

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
        NavigationStack(path: $navigationPath) {
            ScrollViewReader { proxy in
                ScrollView {
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

                            NavigationLink(value: interaction) {
                                BoopInteractionCard(interaction: interaction)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .id(interaction.id) // Add ID for scrolling
                        }
                    }
                    .scrollContentBackground(Visibility.hidden)
                }
                .onChange(of: selectedInteractionID) { _, newID in
                    if let id = newID {
                        // Find the interaction and navigate to it
                        if let interaction = allInteractions.first(where: { $0.id == id }) {
                            // Scroll to the selected interaction
                            withAnimation {
                                proxy.scrollTo(id, anchor: .top)
                            }
                            // Navigate to detail after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(interaction)
                            }
                        }
                        // Clear selection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            selectedInteractionID = nil
                        }
                    }
                }
            }
            .pageBackground()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Timeline")
                        .heading1Style()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddManualBoop = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: IconSize.standard, weight: .semibold))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddManualBoop) {
                AddManualBoopView()
            }
            .navigationDestination(for: BoopInteraction.self) { interaction in
                VStack(spacing: Spacing.lg) {
                    Text("Boop Detail")
                        .heading1Style()
                    
                    Text(interaction.title)
                        .heading2Style()
                    
                    Text(interaction.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        .subtitleStyle()
                    
                    if !interaction.location.isEmpty {
                        Text("Location: \(interaction.location)")
                            .subtitleStyle()
                    }
                    
                    Spacer()
                }
                .padding()
                .pageBackground()
            }
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
            // Update contact with latest profile data
            contact.displayName = boop.displayName
            contact.birthday = boop.birthday
            contact.bio = boop.bio
            contact.gradientColorsData = boop.gradientColors.map { Contact.colorToString($0) }
        } else {
            // Create new contact with profile data
            contact = Contact(
                uuid: contactUUID,
                displayName: boop.displayName,
                avatarData: nil,
                birthday: boop.birthday,
                bio: boop.bio,
                gradientColors: boop.gradientColors
            )
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

        // Start Live Activity
        LiveActivityManager.shared.startBoopLiveActivity(
            contactName: boop.displayName,
            contactID: contactUUID,
            interactionID: newInteraction.id,
            gradientColors: boop.gradientColors.map { Contact.colorToString($0) }
        )

        // Show modal (only if Timeline view is visible)
        showBoop = true

        // Hide modal after animation duration (but don't dismiss view)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showBoop = false
        }
    }
}

#Preview("TimelinePage") {
    BoopTimelineView(selectedInteractionID: .constant(nil))
        .modelContainer(for: [Contact.self, UserProfile.self, BoopInteraction.self])
        .environmentObject(BoopManager())
}
