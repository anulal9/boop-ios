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
    var avatarData: Data?
    var birthday: Date?
    var bio: String?

    // Relationship with cascade delete - when Contact is deleted, its interactions are too
    @Relationship(deleteRule: .cascade, inverse: \BoopInteraction.contact)
    var interactions: [BoopInteraction]

    init(uuid: UUID, displayName: String, avatarData: Data? = nil, birthday: Date? = nil, bio: String? = nil, interactions: [BoopInteraction] = []) {
        self.uuid = uuid
        self.displayName = displayName
        self.avatarData = avatarData
        self.birthday = birthday
        self.bio = bio
        self.interactions = interactions
    }
}
