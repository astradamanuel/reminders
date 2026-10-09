import SwiftUI
import Observation
import UserNotifications

@Observable
final class ItemStore {

    private let persistenceEnabled = true

    var items: [Item] = []

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("items.json")
    }

    init() {
        load()
    }

    func add(
        title: String,
        description: String?,
        direction: String?,
        lat: Double?,
        lon: Double?,
        date: Date,
        notificationID: String
    ) {
        let cleanedDescription = description?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalDescription = (cleanedDescription?.isEmpty ?? true)
            ? nil
            : cleanedDescription

        let item = Item(
            title: title,
            details: finalDescription,
            direction: direction,
            lat: lat,
            lon: lon,
            reminderDate: date,
            notificationID: notificationID
        )

        items.append(item)
        sortItems()
        save()
    }

    func update(item updatedItem: Item) {
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
            items[index] = updatedItem
            sortItems()
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            if let notificationID = items[index].notificationID {
                UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(
                        withIdentifiers: [notificationID]
                    )
            }
        }

        items.remove(atOffsets: offsets)
        save()
    }

    func load() {
        guard persistenceEnabled else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            items = try decoder.decode([Item].self, from: data)
            sortItems()
        } catch {
            items = []
        }
    }

    private func save() {
        guard persistenceEnabled else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(items)

            try data.write(
                to: fileURL,
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            print("Error saving:", error)
        }
    }

    private func sortItems() {
        items.sort { first, second in
            let firstDate = first.reminderDate ?? first.createdAt
            let secondDate = second.reminderDate ?? second.createdAt

            return firstDate < secondDate
        }
    }
}
