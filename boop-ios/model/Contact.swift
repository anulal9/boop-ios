//
//  Contact.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//


import Foundation
import SwiftData

@Model
final class Contact {
    var uuid: UUID
    var displayName: String

    // Relationship with cascade delete - when Contact is deleted, its interactions are too
    @Relationship(deleteRule: .cascade, inverse: \BoopInteraction.contact)
    var interactions: [BoopInteraction]

    init(uuid: UUID, displayName: String, interactions: [BoopInteraction] = []) {
        self.uuid = uuid
        self.displayName = displayName
        self.interactions = interactions
    }
}
