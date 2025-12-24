//
//  BoopView.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//

import SwiftUI
import SwiftData

struct BoopView: View {
    @StateObject private var boopManager = BoopManager()
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    @State private var showBoop = false
    @State private var currentBoopDisplayName: String = ""

    private let animationDuration: TimeInterval = 2
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    Text("Timeline")
                        .primaryTextStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("This Week")
                        .heading1Style()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.frame(height: ComponentSize.pageHeaderHeight)

                Spacer()

                LazyVStack {
                    ForEach(entries) { entry in
                        NavigationLink {
                            Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        } label: {
                            buildInteractionCard(entry: entry)
                        }
                    }
                    .onDelete(perform: deleteEntry)
                }
                .scrollContentBackground(Visibility.hidden)
            }
            .pageBackground()
            .overlay {
                if showBoop {
                    ZStack {
                        Color.backgroundPrimary.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: Spacing.xl) {
                            Text("Boop!")
                                .heading1Style()
                            Text(currentBoopDisplayName)
                                .heading2Style()
                        }
                        .cardStyle()
                        .padding(Spacing.lg)
                    }
                }
            }
            .animation(.easeInOut(duration: animationDuration), value: showBoop)
            .onChange(of: boopManager.boopsToRender) { oldValue, newValue in
                // When a new boop arrives, process it
                if !newValue.isEmpty && !showBoop {
                    handleNewBoop()
                }
            }
        }
    }
        
    private func deleteEntry(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }

    private func handleNewBoop() {
        do {
            // Pop the boop from the queue
            let boop = try boopManager.receiveBoopAndRemove()

            // Store display name for modal
            currentBoopDisplayName = boop.displayName

            // Insert entry into database
            withAnimation {
                modelContext.insert(Entry(displayName: boop.displayName))
            }

            // Show modal
            showBoop = true

            // Hide modal after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                showBoop = false
            }
        } catch {
            print("Error attempting to receive boop: \(error)")
        }
    }
}

func buildInteractionCard(entry: Entry) -> BoopInteractionCard {
    let interaction = BoopInteraction(
        title: entry.displayName,
        location: "temp - todo",
        timestamp: entry.timestamp,
        thumbnails: []
    )

    return BoopInteractionCard(interaction: interaction)
}

#Preview("BoopPage") {
    let testEntries: [Entry] = [
        Entry(displayName: "Anuradha Lal")
    ]
    let showBoop = true
    NavigationStack {
        ScrollView {
            Group {
                Text("Timeline")
                    .primaryTextStyle()
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("This Week")
                    .heading1Style()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.frame(height: ComponentSize.pageHeaderHeight)

            Spacer()

            LazyVStack {
                ForEach(testEntries) { entry in
                    NavigationLink {
                        Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    } label: {
                        buildInteractionCard(entry: entry)
                    }
                }
            }
            .scrollContentBackground(Visibility.hidden)
        }
        .pageBackground()
        .overlay {
            if showBoop {
                ZStack {
                    Color.backgroundPrimary.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: Spacing.xl) {
                        Text("Boop!")
                            .heading1Style()
                        Text("From Anu!")
                            .heading1Style()
                    }
                    .cardStyle()
                    .padding(Spacing.lg)
                }
            }
        }
        .animation(.easeInOut(duration: 10), value: showBoop)
    }
}


