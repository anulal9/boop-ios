//
//  ContactsView.swift
//  boop-ios
//
//  Created by Anu Lal on 11/26/25.
//

import SwiftUI
import SwiftData

struct ContactsView: View {
    @Binding var selectedContactID: UUID?
    @Query private var contacts: [Contact]
    @State private var showBoopRanging = false
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                LazyVStack {
                    ForEach(contacts) { contact in
                        NavigationLink(value: contact) {
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
            .navigationDestination(for: Contact.self) { contact in
                ContactDetailView(contact: contact)
            }
            .navigationDestination(for: BoopHistoryRoute.self) { route in
                BoopHistoryView(contact: route.contact)
            }
            .navigationDestination(for: BoopInteraction.self) { interaction in
                BoopInteractionDetailView(interaction: interaction)
            }
            .sheet(isPresented: $showBoopRanging) {
                BoopRangingView(isPresented: $showBoopRanging)
            }
            .onChange(of: selectedContactID) { _, uuid in
                guard let uuid else { return }
                if let contact = contacts.first(where: { $0.uuid == uuid }) {
                    navPath.append(contact)
                }
                selectedContactID = nil
            }
        }
    }

    private func deleteContact(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                ContactRepository.shared.delete(contacts[index])
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
    ContactsView(selectedContactID: .constant(nil))
        .modelContainer(for: Contact.self, inMemory: true)
}
