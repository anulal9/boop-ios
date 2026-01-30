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
    @Query private var contacts: [Contact]
    @State private var showBoop = false
    @State private var currentBoopDisplayName: String = ""
    @State private var selectedContact: Contact? = nil

    private let animationDuration: TimeInterval = 2
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    Text("Contacts")
                        .heading1Style()
                        .frame(maxWidth: .infinity, alignment: .center)
                }.frame(height: ComponentSize.pageHeaderHeight)

                Spacer()

                LazyVStack {
                    ForEach(contacts) { contact in
                        Button(action: {
                            selectedContact = contact
                        }) {
                            buildContactCard(contact: contact)
                        }
                    }
                    .onDelete(perform: deleteContact)
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
            .sheet(item: $selectedContact) { contact in
                BoopHistoryView(contact: contact)
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
        
    private func deleteContact(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(contacts[index])
            }
        }
    }

    private func handleNewBoop() {
        do {
            // Pop the boop from the queue
            let boop = try boopManager.receiveBoopAndRemove()

            // Store display name for modal
            currentBoopDisplayName = boop.displayName

            // Use senderUUID from boop
            let contactUUID = boop.senderUUID
            if let contact = contacts.first(where: { $0.uuid == contactUUID }) {
                let newInteraction = BoopInteraction(
                    title: boop.displayName,
                    location: "temp - todo",
                    timestamp: Date()
                )
                contact.interactions.append(newInteraction)
            } else {
                let newInteraction = BoopInteraction(
                    title: boop.displayName,
                    location: "temp - todo",
                    timestamp: Date()
                )
                let newContact = Contact(uuid: contactUUID, displayName: boop.displayName, interactions: [newInteraction])
                withAnimation {
                    modelContext.insert(newContact)
                }
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

@ViewBuilder
func buildContactCard(contact: Contact) -> some View {
    ContactInteractionCard(contact: contact) {
        // Optionally handle tap
    }
}

struct BoopHistoryView: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Boop History for \(contact.displayName)")
                .heading1Style()
            List(contact.interactions) { interaction in
                BoopInteractionCard(interaction: interaction)
            }
        }
        .padding()
    }
}
