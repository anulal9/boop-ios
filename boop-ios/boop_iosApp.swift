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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Entry.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Ensure the Application Support directory exists before SwiftData tries to use it
            let storeURL = modelConfiguration.url
            let directory = storeURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
