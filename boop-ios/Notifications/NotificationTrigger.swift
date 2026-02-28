//
//  NotificationTrigger.swift
//  boop-ios
//

import Foundation
import UserNotifications

enum NotificationTriggerKind: String, Codable {
    case immediate
    case once
    case cadence
}

enum CadenceInterval: String, Codable {
    case daily
    case weekly
}

enum NotificationTrigger {
    /// Fire after a 5-second delay.
    case immediate

    /// Fire once at the specified date components.
    case once(on: DateComponents)

    /// Fire repeatedly at the given date components on the given interval.
    /// e.g. `.cadence(on: DateComponents(hour: 18, minute: 0), every: .weekly)`
    case cadence(on: DateComponents, every: CadenceInterval)

    var kind: NotificationTriggerKind {
        switch self {
        case .immediate: return .immediate
        case .once: return .once
        case .cadence: return .cadence
        }
    }

    func toUNTrigger() -> UNNotificationTrigger {
        switch self {
        case .immediate:
            return UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        case .once(let components):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .cadence(let components, let interval):
            // Build date components scoped to the interval.
            // Weekly includes weekday; daily does not.
            var dc = DateComponents()
            dc.hour = components.hour
            dc.minute = components.minute
            if interval == .weekly {
                dc.weekday = components.weekday
            }
            return UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        }
    }

    /// Populate an intent's trigger fields from this trigger.
    func apply(to intent: NotificationIntent) {
        intent.triggerKind = kind
        switch self {
        case .immediate:
            intent.triggerInterval = nil
            intent.triggerWeekday = nil
            intent.triggerHour = nil
            intent.triggerMinute = nil
        case .once(let components):
            intent.triggerInterval = nil
            intent.triggerWeekday = components.weekday
            intent.triggerHour = components.hour
            intent.triggerMinute = components.minute
        case .cadence(let components, let interval):
            intent.triggerInterval = interval
            intent.triggerWeekday = components.weekday
            intent.triggerHour = components.hour
            intent.triggerMinute = components.minute
        }
    }

    /// Reconstruct from stored intent primitives.
    static func from(intent: NotificationIntent) -> NotificationTrigger {
        var components: DateComponents {
            var dc = DateComponents()
            dc.weekday = intent.triggerWeekday
            dc.hour = intent.triggerHour
            dc.minute = intent.triggerMinute
            return dc
        }

        switch intent.triggerKind {
        case .cadence:
            return .cadence(on: components, every: intent.triggerInterval!)
        case .once:
            return .once(on: components)
        case .immediate:
            return .immediate
        }
    }
}
