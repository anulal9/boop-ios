//
//  NotificationManager.swift
//  boop-ios
//

import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    /// Request notification authorization. Returns whether permission was granted.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    /// Schedule a notification request with the OS.
    func schedule(_ request: UNNotificationRequest) async {
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification \(request.identifier): \(error)")
        }
    }

    /// Cancel a single pending notification by identifier.
    func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all pending notifications whose identifier starts with the given prefix.
    func cancelAll(matching prefix: String) async {
        let pending = await center.pendingNotificationRequests()
        let matching = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        if !matching.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }
}
