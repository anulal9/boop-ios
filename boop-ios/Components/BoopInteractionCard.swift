//
//  BoopInteractionCard.swift
//  boop-ios
//
//  SwiftUI component for displaying Boop interactions
//  Converted from Figma design with design tokens
//

import SwiftUI

struct BoopInteractionCard: View {
    let interaction: BoopInteraction
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                // Thumbnail(s)
                thumbnailView
                    .frame(width: thumbnailWidth, height: ThumbnailSize.single)

                // Content
                VStack(alignment: .leading, spacing: LayoutConstant.cardContentGap) {
                    // Title
                    Text(interaction.title)
                        .font(.heading2)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    // Subtitle: location • date • time
                    // TimelineView updates automatically as time passes
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        HStack(spacing: 0) {
                            subtitleText(interaction.location)
                            bullet
                            subtitleText(relativeTimeString(for: interaction.timestamp))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: IconSize.standard, weight: .semibold))
                    .foregroundColor(.accentPrimary)
                    .frame(width: IconSize.xsmall)
            }
            .padding(.horizontal, Spacing.lg)
            .frame(height: ComponentSize.cardHeight)
        }
        .buttonStyle(PlainButtonStyle())
        .cardStyle()
    }

    // MARK: - Thumbnail Views

    @ViewBuilder
    private var thumbnailView: some View {
        switch interaction.thumbnailCount {
        case 1:
            singleThumbnail
        case 2:
            doubleThumbnail
        case 3...:
            tripleThumbnail
        default:
            EmptyView()
        }
    }

    private var thumbnailWidth: CGFloat {
        switch interaction.thumbnailCount {
        case 1: return ThumbnailSize.single
        case 2: return ThumbnailSize.doubleWidth
        case 3...: return ThumbnailSize.tripleWidth
        default: return 0
        }
    }

    // Single circular thumbnail
    private var singleThumbnail: some View {
        Circle()
            .fill(Color.formBackgroundInactive)
            .overlay(
                Circle()
                    .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
            )
            .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
    }

    // Two thumbnails slightly overlapping
    private var doubleThumbnail: some View {
        ZStack(alignment: .topLeading) {
            // Left thumbnail (back)
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                .position(x: ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)

            // Right thumbnail (front)
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                .position(x: ThumbnailOffset.double + ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)
        }
        .frame(width: ThumbnailSize.doubleWidth, height: ThumbnailSize.single, alignment: .leading)
    }

    // Three overlapping thumbnails
    private var tripleThumbnail: some View {
        ZStack(alignment: .topLeading) {
            // Front thumbnail (leftmost)
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                .position(x: ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)

            // Middle thumbnail
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                .position(x: ThumbnailOffset.middle + ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)

            // Back thumbnail (rightmost)
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                .position(x: ThumbnailOffset.back + ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)
        }
        .frame(width: ThumbnailSize.tripleWidth, height: ThumbnailSize.single, alignment: .leading)
    }

    // MARK: - Helper Views

    private func subtitleText(_ text: String) -> some View {
        Text(text)
            .font(.subtitle)
            .foregroundColor(.textMuted)
            .lineLimit(1)
    }

    private var bullet: some View {
        Text(" • ")
            .font(.subtitle)
            .foregroundColor(.textMuted)
    }

    // MARK: - Helper Functions

    private func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }
}

// MARK: - Preview


#Preview("Single Thumbnail") {
    VStack(spacing: Spacing.lg) {
        BoopInteractionCard(
            interaction: BoopInteraction(
                title: "Hang with Aparna",
                location: "Stuytown, NYC",
                timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                imageData: [Data()]
            )
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}


#Preview("Double Thumbnail") {
    VStack(spacing: Spacing.lg) {
        BoopInteractionCard(
            interaction: BoopInteraction(
                title: "Anish, Sarem...",
                location: "John St, NYC",
                timestamp: Date().addingTimeInterval(-604800), // 1 week ago
                imageData: [Data(), Data()]
            )
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}


#Preview("Triple Thumbnail") {
    VStack(spacing: Spacing.lg) {
        BoopInteractionCard(
            interaction: BoopInteraction(
                title: "Anu, Jesse, Sarem",
                location: "Joyface, NYC",
                timestamp: Date().addingTimeInterval(-31536000), // 1 year ago
                imageData: [Data(), Data(), Data()]
            )
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}