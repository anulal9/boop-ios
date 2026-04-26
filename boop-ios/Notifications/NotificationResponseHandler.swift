//
//  NotificationResponseHandler.swift
//  boop-ios
//

import Foundation
import UserNotifications

@MainActor
final class NotificationResponseHandler: NSObject, @preconcurrency UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationResponseHandler()

    @Published var pendingContactUUID: UUID? = nil

    private override init() { super.init() }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        if id.hasPrefix("contactReminder.") {
            let uuidString = String(id.dropFirst("contactReminder.".count))
            pendingContactUUID = UUID(uuidString: uuidString)
        }
        completionHandler()
    }

    // Show banners even while the app is foregrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
