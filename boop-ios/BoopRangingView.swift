//
//  BoopRangingView.swift
//  boop-ios
//
//  Handles Bluetooth ranging/scanning for new boops
//

import SwiftUI
import SwiftData

struct BoopRangingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var boopManager: BoopManager
    @Environment(\.modelContext) private var modelContext
    @Query private var contacts: [Contact]
    @State private var showBoop = false
    @State private var currentBoopDisplayName: String = ""

    private let animationDuration: TimeInterval = 2

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                // Scanning indicator
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.accentPrimary)

                    Text("Looking for nearby devices...")
                        .heading2Style()
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageBackground()
            .ignoresSafeArea(edges: .horizontal)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
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
                // When a new boop arrives, process it and close the view
                if !newValue.isEmpty && !showBoop {
                    handleNewBoop()
                }
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

            // Hide modal and dismiss view after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                showBoop = false
                // Close the ranging view
                isPresented = false
            }
        } catch {
            print("Error attempting to receive boop: \(error)")
        }
    }
}
