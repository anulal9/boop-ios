//
//  BoopInteractionTimelineBody.swift
//  boop-ios
//
//  Reusable time-grouped interaction list and detail view.
//  Place BoopInteractionTimelineBody inside a ScrollView that lives
//  within a NavigationStack or NavigationView.
//

import SwiftUI

// MARK: - Shared List Body

struct BoopInteractionTimelineBody: View {
    let interactions: [BoopInteraction]

    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private func headerText(for date: Date) -> String {
        let text = relativeDateFormatter.localizedString(for: date, relativeTo: Date())
        let sanitized = text.trimmingCharacters(in: .whitespaces).lowercased()
        let words = sanitized.components(separatedBy: .whitespaces)
        if words.contains(where: { $0.contains("minute") || $0.contains("hour") }) {
            return "Today"
        }
        return text.capitalized
    }

    var body: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(Array(interactions.enumerated()), id: \.element.id) { index, interaction in
                let currentHeader = headerText(for: interaction.timestamp)
                let previousHeader = index > 0 ? headerText(for: interactions[index - 1].timestamp) : nil

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
                .id(interaction.id)
            }
        }
    }
}

// MARK: - Shared Detail View

struct BoopInteractionDetailView: View {
    let interaction: BoopInteraction

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
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
        .navigationTitle("Boop Detail")
        .navigationBarTitleDisplayMode(.inline)
        .pageBackground()
    }
}
