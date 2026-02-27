//
//  BoopNotificationType.swift
//  boop-ios
//

import Foundation

enum BoopNotificationType {
    case boopReceived(contactName: String, contactUUID: UUID)
    case contactReminder(contactName: String, contactUUID: UUID)
    case dailySummary(boopCount: Int)

    var title: String {
        switch self {
        case .boopReceived(let contactName, _):
            return "Boop from \(contactName)!"
        case .contactReminder(let contactName, _):
            return "Missing \(contactName)?"
        case .dailySummary:
            return "Daily Boop Summary"
        }
    }

    var body: String {
        switch self {
        case .boopReceived(let contactName, _):
            return "You just booped with \(contactName)!"
        case .contactReminder(let contactName, _):
            return "You haven't booped with \(contactName) in a while. Go say hi!"
        case .dailySummary(let boopCount):
            if boopCount == 0 {
                return "No boops today. Get out there and connect!"
            }
            return "You had \(boopCount) boop\(boopCount == 1 ? "" : "s") today!"
        }
    }

    var typeIdentifier: NotificationTypeIdentifier {
        switch self {
        case .boopReceived: return .boopReceived
        case .contactReminder: return .contactReminder
        case .dailySummary: return .dailySummary
        }
    }

    var entityUUID: UUID? {
        switch self {
        case .boopReceived(_, let contactUUID): return contactUUID
        case .contactReminder(_, let contactUUID): return contactUUID
        case .dailySummary: return nil
        }
    }
}
