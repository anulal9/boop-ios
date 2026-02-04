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

    private var nearbyDevices: [NearbyDevice] {
        let devices = boopManager.getNearbyDevices()
        print("🎨 BoopRangingView: Building UI for \(devices.count) nearby device(s)")

        let result = devices.map { (id, distance) in
            // Check if this device is a saved contact
            let savedContact = contacts.first(where: { $0.uuid == id })

            // Prefer saved contact name, then transmitted name, then fallback
            let displayName = savedContact?.displayName
                ?? boopManager.displayNames[id]
                ?? "Unknown User"

            print("🎨 BoopRangingView: Device \(id.uuidString.prefix(8))")
            print("   - Saved contact: \(savedContact?.displayName ?? "nil")")
            print("   - Transmitted name: \(boopManager.displayNames[id] ?? "nil")")
            print("   - Final displayName: '\(displayName)'")

            return NearbyDevice(
                id: id,
                displayName: displayName,
                distance: distance,
                isSelected: boopManager.mySelections.contains(id)
            )
        }
        .sorted { $0.distance.rawValue < $1.distance.rawValue }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Devices list
                if nearbyDevices.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.accentPrimary)

                        Text("Looking for nearby devices...")
                            .subtitleStyle()
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(nearbyDevices) { device in
                                DeviceRow(
                                    device: device,
                                    isSelected: boopManager.mySelections.contains(device.id),
                                    otherSelected: boopManager.theirSelections.contains(device.id)
                                ) {
                                    boopManager.selectDevice(device.id)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageBackground()
            .ignoresSafeArea(edges: .horizontal)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select a User")
                        .heading1Style()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: IconSize.standard, weight: .semibold))
                            .foregroundColor(.accentPrimary)
                    }
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
            .onChange(of: boopManager.latestBoopEvent) { oldValue, newValue in
                // Only handle if this view is presented and event is new
                guard let event = newValue, !showBoop else { return }
                handleNewBoop(event: event)
            }
        }
    }

    private func handleNewBoop(event: BoopEvent) {
        let boop = event.boop

        // Store display name for modal
        currentBoopDisplayName = boop.displayName

        // Use senderUUID from boop
        let contactUUID = boop.senderUUID

        // Find or create contact
        let contact: Contact
        if let existingContact = contacts.first(where: { $0.uuid == contactUUID }) {
            contact = existingContact
            // Update contact with latest profile data
            contact.displayName = boop.displayName
            contact.birthday = boop.birthday
            contact.bio = boop.bio
        } else {
            // Create new contact with profile data
            contact = Contact(
                uuid: contactUUID,
                displayName: boop.displayName,
                avatarData: nil,
                birthday: boop.birthday,
                bio: boop.bio
            )
            modelContext.insert(contact)
        }

        // Create interaction with contact relationship
        let newInteraction = BoopInteraction(
            title: boop.displayName,
            location: "temp - todo",
            timestamp: event.timestamp,
            contact: contact  // Set relationship
        )
        modelContext.insert(newInteraction)  // Insert as top-level entity
        contact.interactions.append(newInteraction)  // Also add to contact's array

        // Show modal
        showBoop = true

        // Hide modal and dismiss view after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showBoop = false
            isPresented = false
        }
    }
}

// MARK: - Device Row Component
struct DeviceRow: View {
    let device: NearbyDevice
    let isSelected: Bool
    let otherSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Distance indicator
                Text(device.distanceEmoji)
                    .font(.system(size: 30))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(device.displayName)
                        .heading2Style()

                    HStack(spacing: Spacing.xs) {
                        Text(device.distanceText)
                            .subtitleStyle()

                        if otherSelected {
                            Text("• Wants to boop you!")
                                .subtitleStyle()
                                .foregroundColor(.accentPrimary)
                        }
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentPrimary)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.textMuted)
                        .font(.system(size: 24))
                }
            }
            .padding(Spacing.md)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
