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
        ZStack {
            Text("Timeline").foregroundColor(Color.white).font(.title).fontWeight(.bold).fontDesign(.rounded)
            Spacer()
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        Text("Boop at \(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard)) from \(entry.user)")
                    } label: {
                        Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteEntry)
            }.background(Color.pink)
            
            if showBoop {
                Color.black.opacity(0.4).ignoresSafeArea() // dim background
                VStack(spacing: 20) {
                    Text("Boop!").font(.title)
                    Text(insertEntryAndGetUserText())
                }.background(Color.pink)
            }
        }
        .animation(.easeInOut(duration: 10), value: showBoop)
        .onDisappear()
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

