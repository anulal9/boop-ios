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
    let uuid: UUID
    var displayName: String
    var interactions: [BoopInteraction]

    init(uuid: UUID, displayName: String, interactions: [BoopInteraction] = []) {
        self.uuid = uuid
        self.displayName = displayName
        self.interactions = interactions
    }
}
