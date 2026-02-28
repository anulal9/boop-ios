//
//  NotificationScheduler.swift
//  boop-ios
//

import Foundation
import SwiftData

@ModelActor
actor NotificationScheduler {

    /// Create or update an intent for a notification type + entity.
    /// If an intent already exists for this type+entity, updates it in place.
    func setSchedule(
        type: NotificationType,
        trigger: NotificationTrigger
    ) async {
        let existing = fetchIntent(typeIdentifier: type.typeIdentifier, entityUUID: type.entityUUID)

        let intent: NotificationIntent
        if let existing {
            NotificationBuilder.updateIntent(existing, type: type, trigger: trigger)
            intent = existing
        } else {
            intent = NotificationBuilder.buildIntent(type: type, trigger: trigger)
            modelContext.insert(intent)
        }

        try? modelContext.save()

        let request = NotificationBuilder.buildRequest(from: intent)
        await NotificationManager.shared.schedule(request)
    }

    /// Remove an intent and cancel its OS notification.
    func removeSchedule(
        typeIdentifier: NotificationTypeIdentifier,
        entityUUID: UUID?
    ) async {
        guard let existing = fetchIntent(typeIdentifier: typeIdentifier, entityUUID: entityUUID) else {
            return
        }

        let notificationId = existing.notificationIdentifier
        modelContext.delete(existing)
        try? modelContext.save()

        await NotificationManager.shared.cancel(identifier: notificationId)
    }

    /// Pause or resume an intent without deleting it.
    func setActive(
        _ active: Bool,
        typeIdentifier: NotificationTypeIdentifier,
        entityUUID: UUID?
    ) async {
        guard let existing = fetchIntent(typeIdentifier: typeIdentifier, entityUUID: entityUUID) else {
            return
        }

        existing.isActive = active
        existing.updatedAt = Date()
        try? modelContext.save()

        if active {
            let request = NotificationBuilder.buildRequest(from: existing)
            await NotificationManager.shared.schedule(request)
        } else {
            await NotificationManager.shared.cancel(identifier: existing.notificationIdentifier)
        }
    }

    /// Re-sync all active intents with the OS (e.g., on app launch).
    func syncAllSchedules() async {
        let predicate = #Predicate<NotificationIntent> { $0.isActive }
        let descriptor = FetchDescriptor<NotificationIntent>(predicate: predicate)

        guard let intents = try? modelContext.fetch(descriptor) else { return }

        for intent in intents {
            let request = NotificationBuilder.buildRequest(from: intent)
            await NotificationManager.shared.schedule(request)
        }
    }

    // MARK: - Private

    private func fetchIntent(typeIdentifier: NotificationTypeIdentifier, entityUUID: UUID?) -> NotificationIntent? {
        let predicate: Predicate<NotificationIntent>
        if let entityUUID {
            predicate = #Predicate<NotificationIntent> {
                $0.typeIdentifier == typeIdentifier && $0.entityUUID == entityUUID
            }
        } else {
            predicate = #Predicate<NotificationIntent> {
                $0.typeIdentifier == typeIdentifier && $0.entityUUID == nil
            }
        }

        var descriptor = FetchDescriptor<NotificationIntent>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try? modelContext.fetch(descriptor).first
    }
}
