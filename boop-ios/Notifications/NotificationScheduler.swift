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
        type: BoopNotificationType,
        trigger: BoopNotificationTrigger
    ) async {
        let typeId = type.typeIdentifier
        let entityId = type.entityUUID

        let existing = fetchIntent(typeIdentifier: typeId, entityUUID: entityId)

        let intent: NotificationIntent
        if let existing {
            existing.title = type.title
            existing.body = type.body
            existing.isActive = true
            existing.updatedAt = Date()
            trigger.apply(to: existing)
            intent = existing
        } else {
            intent = NotificationIntent(
                typeIdentifier: typeId,
                entityUUID: entityId,
                title: type.title,
                body: type.body,
                triggerKind: ""  // will be set by apply
            )
            trigger.apply(to: intent)
            modelContext.insert(intent)
        }

        try? modelContext.save()

        let request = BoopNotificationBuilder.build(from: intent)
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
            let request = BoopNotificationBuilder.build(from: existing)
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
            let request = BoopNotificationBuilder.build(from: intent)
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
