//
//  boop_iosApp.swift
//  boop-ios
//
//  Created by Aparna Natarajan on 10/30/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct boop_iosApp: App {
    private var schema: Schema
    private var modelConfiguration: ModelConfiguration
    @State var sharedModelContainer: ModelContainer?
    @StateObject private var boopManager = BoopManager()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab: Int = 0
    @State private var selectedInteractionID: UUID?
    @State private var selectedContactID: UUID?

    init() {
        self.schema = Schema([
                Contact.self,
                UserProfile.self,
                BoopInteraction.self,
                NotificationIntent.self,
            ])
        self.modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let configurationUrl = self.modelConfiguration.url
        Task {
            await StorageCoordinator.shared.initialize(with: configurationUrl)
            await UserDataStore.shared.warmup()
        }
    }
    
    @MainActor
    private func setModelContainer() async {
        do {
            try await StorageCoordinator.shared.waitForInitialization()
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Unable to create model container \(error)")
        }
    }
    
    private func handleURL(_ url: URL) {
        print("📱 Deep link received: \(url)")
        
        // Handle boop://timeline or boop://timeline/{interactionID}
        if url.scheme == "boop", url.host == "timeline" {
            selectedTab = 0 // Switch to timeline tab
            
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if let idString = pathComponents.first, let interactionID = UUID(uuidString: idString) {
                selectedInteractionID = interactionID
                print("📱 Navigating to interaction: \(interactionID)")
            } else {
                selectedInteractionID = nil
                print("📱 Navigating to timeline")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = sharedModelContainer {
                    RootView(selectedTab: $selectedTab, selectedInteractionID: $selectedInteractionID, selectedContactID: $selectedContactID)
                        .modelContainer(container)
                        .environmentObject(boopManager)
                        .environmentObject(locationManager)
                        .onOpenURL { url in
                            handleURL(url)
                        }
                } else {
                    VStack
                    {
                        Spacer()
                        ProgressView("Getting Boop Ready for you...")
                        Spacer()
                    }
                }
            }
            .task {
                UNUserNotificationCenter.current().delegate = NotificationResponseHandler.shared
                await setModelContainer()
                locationManager.requestPermissionIfNeeded()
                if let container = sharedModelContainer {
                    ModelContextProvider.shared.setModelContainer(container)
                    boopManager.setModelContainer(container)
                }
                boopManager.setLocationManager(locationManager)
                boopManager.start()
                let granted = await NotificationManager.shared.requestAuthorization()
                if let container = sharedModelContainer {
                    let scheduler = NotificationScheduler(modelContainer: container)
                    await scheduler.syncAllSchedules()

                    if granted {
                        await scheduler.setSchedule(
                            type: .weeklyPlanning,
                            trigger: .cadence(
                                on: DateComponents(hour: 17, minute: 0, weekday: 1),
                                every: .weekly
                            )
                        )
                        await scheduler.syncContactReminders()
                    }
                }
            }
            .onReceive(NotificationResponseHandler.shared.$pendingContactUUID) { uuid in
                guard let uuid else { return }
                selectedContactID = uuid
                selectedTab = 1
                NotificationResponseHandler.shared.pendingContactUUID = nil
            }
        }
    }
}
