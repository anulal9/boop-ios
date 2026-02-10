//
//  LiveActivityManager.swift
//  boop-ios
//
//  Created by Aparna Natarajan on 02/09/26.
//

import Foundation
import ActivityKit
import UserNotifications

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<BoopLiveActivityAttributes>?

    func startBoopLiveActivity(contactName: String) {
        if #available(iOS 16.1, *) {
            let authInfo = ActivityAuthorizationInfo()
            print("📊 Activity Authorization - Enabled: \(authInfo.areActivitiesEnabled)")
            print("📊 Frequent pushes enabled: \(authInfo.frequentPushesEnabled)")
            logNotificationSettings()

            guard authInfo.areActivitiesEnabled else {
                print("⚠️ Live Activities are not enabled on this device")
                return
            }

            let existingCount = Activity<BoopLiveActivityAttributes>.activities.count
            print("📊 Existing boop activities: \(existingCount)")

            if let existing = Activity<BoopLiveActivityAttributes>.activities.first {
                print("✅ Reusing existing activity: \(existing.id)")
                currentActivity = existing
                return
            }

            let attributes = BoopLiveActivityAttributes()
            let contentState = BoopLiveActivityAttributes.ContentState(boopTime: Date())

            do {
                let staleDate = Date().addingTimeInterval(300)
                let content = ActivityContent(state: contentState, staleDate: staleDate)
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                currentActivity = activity
                print("✅ Live Activity started! id=\(activity.id) state=\(activity.activityState)")
            } catch {
                print("❌ Failed to start Live Activity: \(error.localizedDescription)")
                if let error = error as NSError? {
                    print("Error code: \(error.code), domain: \(error.domain)")
                    print("Error userInfo: \(error.userInfo)")
                }
            }
        }
    }

    private func logNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📊 Notification settings: status=\(settings.authorizationStatus.rawValue) alerts=\(settings.alertSetting.rawValue)")
        }
    }
}
