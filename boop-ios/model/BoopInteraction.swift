//
//  BoopInteraction.swift
//  boop-ios
//
//  Model for Boop interaction data displayed in cards
//


import Foundation
import SwiftData

@Model
final class BoopInteraction {
    let id: UUID
    var title: String
    var location: String
    var timestamp: Date
    var imageData: [Data] // Use Data for images

    // Relationship to Contact
    var contact: Contact?

    init(title: String, location: String, timestamp: Date, imageData: [Data] = [], contact: Contact? = nil) {
        self.id = UUID()
        self.title = title
        self.location = location
        self.timestamp = timestamp
        self.imageData = imageData
        self.contact = contact
    }

    var thumbnailCount: Int {
        imageData.count
    }
}
