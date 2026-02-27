//
//  NotificationIntent.swift
//  boop-ios
//

import Foundation
import SwiftData

enum NotificationTypeIdentifier: String, Codable {
    case boopReceived
    case contactReminder
    case dailySummary
}

@Model
final class NotificationIntent {
    var id: UUID
    var typeIdentifier: NotificationTypeIdentifier
    var entityUUID: UUID?
    var title: String
    var body: String

    // Trigger config (stored as primitives for SwiftData)
    var triggerKind: String         // "cadence" | "exactTime" | "immediate"
    var triggerInterval: Double?    // seconds, for cadence
    var triggerHour: Int?           // for exactTime
    var triggerMinute: Int?         // for exactTime
    var triggerRepeats: Bool

    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    /// Deterministic notification identifier used for OS scheduling.
    var notificationIdentifier: String {
        "\(typeIdentifier.rawValue).\(entityUUID?.uuidString ?? "global")"
    }

    init(
        id: UUID = UUID(),
        typeIdentifier: NotificationTypeIdentifier,
        entityUUID: UUID? = nil,
        title: String,
        body: String,
        triggerKind: String,
        triggerInterval: Double? = nil,
        triggerHour: Int? = nil,
        triggerMinute: Int? = nil,
        triggerRepeats: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.typeIdentifier = typeIdentifier
        self.entityUUID = entityUUID
        self.title = title
        self.body = body
        self.triggerKind = triggerKind
        self.triggerInterval = triggerInterval
        self.triggerHour = triggerHour
        self.triggerMinute = triggerMinute
        self.triggerRepeats = triggerRepeats
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
