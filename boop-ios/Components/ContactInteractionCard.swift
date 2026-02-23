//
//  BoopInteractionCard.swift
//  boop-ios
//
//  SwiftUI component for displaying Boop interactions
//  Converted from Figma design with design tokens
//

import SwiftUI


struct ContactInteractionCard: View {
    let contact: Contact
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: Spacing.md) {
                // Thumbnail(s) from last interaction if available
                if let last = contact.interactions.last {
                    ContactInteractionThumbnail(interaction: last)
                        .frame(width: thumbnailWidth(for: last), height: ThumbnailSize.single)
                } else {
                    Circle()
                        .fill(Color.formBackgroundInactive)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                        )
                        .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                }

                // Content
                VStack(alignment: .leading, spacing: LayoutConstant.cardContentGap) {
                    // Title: Contact name
                    Text(contact.displayName)
                        .font(.heading2)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    // Subtitle: number of boops and last boop time
                    if let last = contact.interactions.last {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            HStack(spacing: 0) {
                                Text("\(contact.interactions.count) boop\(contact.interactions.count == 1 ? "" : "s")")
                                    .font(.subtitle)
                                    .foregroundColor(.textMuted)
                                bullet
                                Text(relativeTimeString(for: last.timestamp))
                                    .font(.subtitle)
                                    .foregroundColor(.textMuted)
                            }
                        }
                    } else {
                        Text("No boops yet")
                            .font(.subtitle)
                            .foregroundColor(.textMuted)
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

    // Helper for thumbnail width
    private func thumbnailWidth(for interaction: BoopInteraction) -> CGFloat {
        switch interaction.thumbnailCount {
        case 1: return ThumbnailSize.single
        case 2: return ThumbnailSize.doubleWidth
        case 3...: return ThumbnailSize.tripleWidth
        default: return ThumbnailSize.single
        }
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

    private func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }
}

// Extracted thumbnail logic for reuse
struct ContactInteractionThumbnail: View {
    let interaction: BoopInteraction
    var body: some View {
        switch interaction.thumbnailCount {
        case 1:
            Circle()
                .fill(Color.formBackgroundInactive)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                )
                .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
        case 2:
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(Color.formBackgroundInactive)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                    )
                    .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                    .position(x: ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)
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
        case 3...:
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(Color.formBackgroundInactive)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                    )
                    .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                    .position(x: ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)
                Circle()
                    .fill(Color.formBackgroundInactive)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.accentPrimary, lineWidth: ThumbnailSize.borderWidth)
                    )
                    .frame(width: ThumbnailSize.single, height: ThumbnailSize.single)
                    .position(x: ThumbnailOffset.middle + ThumbnailSize.single / 2, y: ThumbnailSize.single / 2)
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
        default:
            EmptyView()
        }
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
