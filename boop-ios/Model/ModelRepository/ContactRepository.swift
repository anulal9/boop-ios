//
//  ContactRepository.swift
//  boop-ios
//
//  Singleton repository for Contact model CRUD operations.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ContactRepository {
    static let shared = ContactRepository()
    private var modelContext: ModelContext? { ModelContextProvider.shared.context }

    private init() {}

    // MARK: - Read

    /// Find an existing contact by its device UUID.
    func find(byUUID uuid: UUID) -> Contact? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<Contact>(predicate: #Predicate { $0.uuid == uuid })
        return (try? modelContext.fetch(descriptor))?.first
    }

    // MARK: - Create / Update

    /// Find a contact by UUID and update its profile fields, or create a new one if not found.
    func findOrCreate(
        uuid: UUID,
        displayName: String,
        birthday: Date?,
        bio: String?,
        gradientColors: [Color]
    ) -> Contact? {
        guard let modelContext else { return nil }

        if let existing = find(byUUID: uuid) {
            existing.displayName = displayName
            existing.birthday = birthday
            existing.bio = bio
            existing.gradientColorsData = gradientColors.map { Contact.colorToString($0) }
            return existing
        }

        let contact = Contact(
            uuid: uuid,
            displayName: displayName,
            birthday: birthday,
            bio: bio,
            gradientColors: gradientColors
        )
        modelContext.insert(contact)
        save()
        return contact
    }

    // MARK: - Delete

    /// Delete a contact (cascades to its interactions) and cancels its pending reminder.
    func delete(_ contact: Contact) {
        guard let modelContext else { return }

        // Cancel and remove any pending contact reminder for this contact
        let contactUUID = contact.uuid
        let descriptor = FetchDescriptor<NotificationIntent>(
            predicate: #Predicate { $0.entityUUID == contactUUID }
        )
        if let intent = (try? modelContext.fetch(descriptor))?.first {
            let notifId = intent.notificationIdentifier
            modelContext.delete(intent)
            Task {
                await NotificationManager.shared.cancel(identifier: notifId)
            }
        }

        modelContext.delete(contact)
        save()
    }

    /// Update the reminder interval for a contact and persist.
    func updateReminderInterval(_ contact: Contact, intervalMinutes: Int?) {
        contact.reminderIntervalMinutes = intervalMinutes
        save()
    }

    // MARK: - Save

    /// Persist pending changes to the store.
    private func save() {
        try? modelContext?.save()
    }
}
