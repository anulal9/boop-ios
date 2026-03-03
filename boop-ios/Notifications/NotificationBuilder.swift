//
//  NotificationBuilder.swift
//  boop-ios
//

import Foundation
import UserNotifications

struct NotificationBuilder {

    /// Create a new `NotificationIntent` from a type and trigger.
    static func buildIntent(
        type: NotificationType,
        trigger: NotificationTrigger
    ) -> NotificationIntent {
        let intent = NotificationIntent(
            typeIdentifier: type.typeIdentifier,
            entityUUID: type.entityUUID,
            title: type.title,
            body: type.body,
            triggerKind: trigger.kind
        )
        trigger.apply(to: intent)
        return intent
    }

    /// Update an existing `NotificationIntent` with new type and trigger values.
    static func updateIntent(
        _ intent: NotificationIntent,
        type: NotificationType,
        trigger: NotificationTrigger
    ) {
        intent.title = type.title
        intent.body = type.body
        intent.isActive = true
        intent.updatedAt = Date()
        trigger.apply(to: intent)
    }

    /// Build a `UNNotificationRequest` from a persisted intent.
    static func buildRequest(from intent: NotificationIntent) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = intent.title
        content.body = intent.body
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = NotificationTrigger.from(intent: intent).toUNTrigger()

        return UNNotificationRequest(
            identifier: intent.notificationIdentifier,
            content: content,
            trigger: trigger
        )
    }
}
