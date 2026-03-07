//
//  BoopLiveActivityAttributes.swift
//  Shared
//
//  Created by Aparna Natarajan on 02/16/26.
//

import Foundation
import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
public struct BoopLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var contactName: String
        public var contactID: UUID
        public var interactionID: UUID?
        public var boopTime: Date
        
        public init(
            contactName: String,
            contactID: UUID,
            interactionID: UUID? = nil,
            boopTime: Date
        ) {
            self.contactName = contactName
            self.contactID = contactID
            self.interactionID = interactionID
            self.boopTime = boopTime
        }
    }
    
    public init() {}
}

// Helper function for formatting time consistently across the app
public func formatRelativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}
