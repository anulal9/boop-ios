//
//  BoopInteraction.swift
//  boop-ios
//
//  Model for Boop interaction data displayed in cards
//

import Foundation
import SwiftUI

struct BoopInteraction: Identifiable {
    let id = UUID()
    let title: String
    let location: String
    let timestamp: Date
    let thumbnails: [UIImage]

    var thumbnailCount: Int {
        thumbnails.count
    }

    // Sample data for preview
    static let samples: [BoopInteraction] = [
        BoopInteraction(
            title: "Hang with Aparna",
            location: "Stuytown, NYC",
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            thumbnails: []
        ),
        BoopInteraction(
            title: "Anish, Sarem...",
            location: "John St, NYC",
            timestamp: Date().addingTimeInterval(-604800), // 1 week ago
            thumbnails: []
        ),
        BoopInteraction(
            title: "Anu, Jesse, Sarem",
            location: "Joyface, NYC",
            timestamp: Date().addingTimeInterval(-31536000), // 1 year ago
            thumbnails: []
        )
    ]
}
