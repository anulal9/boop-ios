//
//  boop_iosApp.swift
//  boop-ios
//
//  Created by Aparna Natarajan on 10/30/25.
//

import SwiftUI
import SwiftData

@main
struct boop_iosApp: App {
    private var schema: Schema
    private var modelConfiguration: ModelConfiguration
    @State var sharedModelContainer: ModelContainer?
    @StateObject private var boopManager = BoopManager()

    init() {
        self.schema = Schema([
                Contact.self,
                UserProfile.self,
            ])
        self.modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let configurationUrl = self.modelConfiguration.url
        Task {
            await StorageCoordinator.shared.initialize(with: configurationUrl)
            await DataStore.shared.warmup()
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

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = sharedModelContainer {
                    RootView()
                        .modelContainer(container)
                        .environmentObject(boopManager)
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
                await setModelContainer()
            }
        }
    }
}
