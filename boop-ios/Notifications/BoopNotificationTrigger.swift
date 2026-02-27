//
//  BoopNotificationTrigger.swift
//  boop-ios
//

import Foundation
import UserNotifications

enum BoopNotificationTrigger {
    case cadence(interval: TimeInterval, repeats: Bool)
    case exactTime(hour: Int, minute: Int, repeats: Bool)
    case immediate

    func toUNTrigger() -> UNNotificationTrigger? {
        switch self {
        case .cadence(let interval, let repeats):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)
        case .exactTime(let hour, let minute, let repeats):
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        case .immediate:
            // nil trigger means fire immediately
            return nil
        }
    }

    /// Populate a schedule's trigger fields from this trigger.
    func apply(to schedule: NotificationIntent) {
        switch self {
        case .cadence(let interval, let repeats):
            schedule.triggerKind = "cadence"
            schedule.triggerInterval = interval
            schedule.triggerHour = nil
            schedule.triggerMinute = nil
            schedule.triggerRepeats = repeats
        case .exactTime(let hour, let minute, let repeats):
            schedule.triggerKind = "exactTime"
            schedule.triggerInterval = nil
            schedule.triggerHour = hour
            schedule.triggerMinute = minute
            schedule.triggerRepeats = repeats
        case .immediate:
            schedule.triggerKind = "immediate"
            schedule.triggerInterval = nil
            schedule.triggerHour = nil
            schedule.triggerMinute = nil
            schedule.triggerRepeats = false
        }
    }

    /// Reconstruct from stored schedule primitives.
    static func from(schedule: NotificationIntent) -> BoopNotificationTrigger {
        switch schedule.triggerKind {
        case "cadence":
            return .cadence(
                interval: schedule.triggerInterval ?? 60,
                repeats: schedule.triggerRepeats
            )
        case "exactTime":
            return .exactTime(
                hour: schedule.triggerHour ?? 9,
                minute: schedule.triggerMinute ?? 0,
                repeats: schedule.triggerRepeats
            )
        default:
            return .immediate
        }
    }
}
