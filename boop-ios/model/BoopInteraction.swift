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
    var id: UUID
    var title: String
    var location: String
    var timestamp: Date
    var endTimestamp: Date? // optional end time for interactions that span a duration
    var imageData: [Data] // Use Data for images

    // Relationship to Contact
    var contact: Contact?

    init(title: String, location: String, timestamp: Date, endTimestamp: Date? = Date().addingTimeInterval(2 * 60 * 60), imageData: [Data] = [], contact: Contact? = nil) {
        self.id = UUID()
        self.title = title
        self.location = location
        self.timestamp = timestamp
        self.endTimestamp = endTimestamp
        self.imageData = imageData
        self.contact = contact
    }

    var thumbnailCount: Int {
        imageData.count
    }
}
