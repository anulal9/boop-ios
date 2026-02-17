//
//  BoopLiveActivityLiveActivity.swift
//  BoopLiveActivity
//
//  Created by Aparna Natarajan on 2/9/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BoopLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BoopLiveActivityAttributes.self) { context in
            // Lock screen/banner UI
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: context.state.gradientColors.first ?? "#ff7aa2"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Booped with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(context.state.contactName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color(hex: context.state.gradientColors.first ?? "#ff7aa2"))
            .widgetURL(deepLink(for: context.state))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: context.state.gradientColors.first ?? "#ff7aa2"))
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text("Booped with")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(context.state.contactName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            } compactLeading: {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(Color(hex: context.state.gradientColors.first ?? "#ff7aa2"))
            } compactTrailing: {
                Text(context.state.contactName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(Color(hex: context.state.gradientColors.first ?? "#ff7aa2"))
            }
            .widgetURL(deepLink(for: context.state))
        }
    }
    
    private func deepLink(for state: BoopLiveActivityAttributes.ContentState) -> URL {
        if let interactionID = state.interactionID {
            return URL(string: "boop://timeline/\(interactionID.uuidString)")!
        } else {
            return URL(string: "boop://timeline")!
        }
    }
}

// Helper extension to convert hex color strings to SwiftUI Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 122, 162) // Default to accentPrimary
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#if DEBUG
extension BoopLiveActivityAttributes {
    fileprivate static var preview: BoopLiveActivityAttributes {
        BoopLiveActivityAttributes()
    }
}

extension BoopLiveActivityAttributes.ContentState {
    fileprivate static var preview: BoopLiveActivityAttributes.ContentState {
        BoopLiveActivityAttributes.ContentState(
            contactName: "Sarah Chen",
            contactID: UUID(),
            interactionID: UUID(),
            boopTime: Date().addingTimeInterval(-300), // 5 minutes ago
            gradientColors: ["#ff7aa2", "#3a1e3f"]
        )
    }
}

#Preview("Lock Screen", as: .content, using: BoopLiveActivityAttributes.preview) {
    BoopLiveActivityLiveActivity()
} contentStates: {
    BoopLiveActivityAttributes.ContentState.preview
}
#endif
