//
//  Entry.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//

import Foundation
import SwiftData

@Model
final class Entry {
    private(set) var displayName: String
    private(set) var timestamp: Date
    
    init(displayName: String) {
        self.displayName = displayName
        self.timestamp = Date()
    }
}
