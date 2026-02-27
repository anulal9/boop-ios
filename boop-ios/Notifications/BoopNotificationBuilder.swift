//
//  BoopNotificationBuilder.swift
//  boop-ios
//

import Foundation
import UserNotifications

struct BoopNotificationBuilder {

    /// Build a `UNNotificationRequest` from a persisted schedule.
    static func build(from schedule: NotificationIntent) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = schedule.title
        content.body = schedule.body
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = BoopNotificationTrigger.from(schedule: schedule).toUNTrigger()

        return UNNotificationRequest(
            identifier: schedule.notificationIdentifier,
            content: content,
            trigger: trigger
        )
    }
}
