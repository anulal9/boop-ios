//
//  NotificationType.swift
//  boop-ios
//

import Foundation

enum NotificationType {
    case contactReminder(contactName: String, contactUUID: UUID)
    case weeklyPlanning

    var title: String {
        switch self {
        case .contactReminder(let contactName, _):
            return "Missing \(contactName)?"
        case .weeklyPlanning:
            return "It's Sunday"
        }
    }

    var body: String {
        switch self {
        case .contactReminder(let contactName, _):
            return "You haven't booped with \(contactName) in a while. Go say hi!"
        case .weeklyPlanning:
            return "Take a moment to plan who you want to connect with this week."
        }
    }

    var typeIdentifier: NotificationTypeIdentifier {
        switch self {
        case .contactReminder: return .contactReminder
        case .weeklyPlanning: return .weeklyPlanning
        }
    }

    var entityUUID: UUID? {
        switch self {
        case .contactReminder(_, let contactUUID): return contactUUID
        case .weeklyPlanning: return nil
        }
    }
}
