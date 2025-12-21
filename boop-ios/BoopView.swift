//
//  BoopView.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//

import SwiftUI
import SwiftData

struct BoopView: View {
    @StateObject private var boopViewModel = BoopViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    
    var showBoop: Bool {
        !boopViewModel.boopAnimationQueue.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    Text("Timeline")
                        .primaryTextStyle()
                }.frame(height: ComponentSize.pageHeaderHeight)
                
                Spacer()
                
                ZStack {
                    LazyVStack {
                        ForEach(entries) { entry in
                            NavigationLink {
                                Text("Boop at \(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)) from \(entry.user)")
                            } label: {
                                Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
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
        let userString = boopViewModel.getBoopUserFromAnimationQueueAndRemove()
        withAnimation {
            if (userString != "") {
                let user = UUID(uuidString: userString)
                if let nonnulluser = user {
                    modelContext.insert(Entry(user: nonnulluser))
                }
            }
        }
        return userString
    }
}

#Preview("BoopPage") {
    var entries = [
        Entry(user: UUID())
    ]
    NavigationStack {
        ScrollView {
            Group {
                Text("Timeline")
                    .primaryTextStyle()
            }
            .frame(height: ComponentSize.pageHeaderHeight)
            
            LazyVStack {
                ForEach(entries) { entry in
                    NavigationLink {
                        VStack {
                            Text("Boop at \(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)) from \(entry.user)")
                                .heading2Style()
                        }
                    }
                    label: {
                        BoopInteractionCard(interaction: BoopInteraction(title: "Hang with Aparna", location: "John St, NY", date: "Dec 13th, 2025", time: "9pm", thumbnails: []))
                    }
                }
            }
        }
        .pageBackground()
    }
//    .foregroundStyle(.primary)
//    .background(RoundedRectangle(cornerRadius: CornerRadius.lg).opacity(1.0))
}
