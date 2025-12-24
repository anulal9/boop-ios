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
    
    var showBoop: Bool {
        !boopManager.boopsToRender.isEmpty
    }
    
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
                
                ZStack {
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
                    
                    if showBoop {
                        Color.backgroundPrimary.opacity(0.4).ignoresSafeArea() // dim background
                        VStack(spacing: Spacing.xl) {
                            Text("Boop!")
                                .heading1Style()
                            Text(insertEntryAndGetUserText())
                        }
                        .cardStyle()
                        .padding(Spacing.lg)
                    }
                }
                .pageBackground()
                .animation(.easeInOut(duration: AnimationDuration.modal), value: showBoop)
                .onDisappear()
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
    
    private func insertEntryAndGetUserText() -> String {
        do {
            let boop = try boopManager.receiveBoopAndRemove()
            withAnimation {
                modelContext.insert(Entry(displayName: boop.displayName))
            }
            return boop.displayName
        } catch {
            print("Error attempting to receive boop")
            return "User not found"
        }
    }
}

func buildInteractionCard(entry: Entry) -> BoopInteractionCard {
    let dateFormatter = RelativeDateTimeFormatter()
    dateFormatter.dateTimeStyle = RelativeDateTimeFormatter.DateTimeStyle.named
    dateFormatter.unitsStyle = .abbreviated
    
    let interaction = BoopInteraction(
        title: entry.displayName,
        location: "temp - todo",
        date: dateFormatter.localizedString(
            for: entry.timestamp,
            relativeTo: Date.now),
        thumbnails: []
        )
    
    let card = BoopInteractionCard.init(interaction: interaction)
    return card
}

#Preview("BoopPage") {
    let testEntries: [Entry] = [
        Entry(displayName: "Anuradha Lal")
    ]
    
    NavigationStack {
        ScrollView {
            Group {
                Text("Timeline")
                    .primaryTextStyle()
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("This Week")
                    .heading1Style()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: ComponentSize.pageHeaderHeight)
            
            LazyVStack {
                ForEach(testEntries) { entry in
                    NavigationLink {
                        VStack {
                            Text("Boop at \(entry.timestamp) from \(entry.displayName)")
                                .heading2Style()
                        }
                    }
                    label: {
                        buildInteractionCard(entry: entry)
                    }
                }
            }
        }
        .pageBackground()
    }
}
