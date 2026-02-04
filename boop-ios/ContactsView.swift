//
//  ContactsView.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//

import SwiftUI
import SwiftData

struct ContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var selectedContact: Contact? = nil
    @State private var showBoopRanging = false

    var body: some View {
        NavigationStack {
            ScrollView {
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Contacts")
                        .heading1Style()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showBoopRanging = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: IconSize.standard, weight: .semibold))
                            .foregroundColor(.accentPrimary)
                    }
                }
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
            .sheet(isPresented: $showBoopRanging) {
                BoopRangingView(isPresented: $showBoopRanging)
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
}

@ViewBuilder
func buildContactCard(contact: Contact) -> some View {
    ContactInteractionCard(contact: contact) {
        // Optionally handle tap
    }
}

#Preview {
    ContactsView()
        .modelContainer(for: Contact.self, inMemory: true)
}
