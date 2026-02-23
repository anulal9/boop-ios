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
    @Query(sort: \BoopInteraction.timestamp, order: .reverse)
    private var allInteractions: [BoopInteraction]
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
                VStack(alignment: .leading, spacing: Spacing.lg) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                handleBoopVisual(event: event)
            }
        }
    }

    private func handleBoopVisual(event: BoopEvent) {
        let boop = event.boop

        // Store display name for modal
        currentBoopDisplayName = boop.displayName

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
