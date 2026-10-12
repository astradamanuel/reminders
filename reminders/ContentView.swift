import SwiftUI

struct ContentView: View {
    
    @Environment(ItemStore.self) private var store
    @Environment(\.openURL) private var openURL
    
    @State private var showingAddSheet = false
    @State private var itemToEdit: Item?
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {Section("My reminders") {
                if store.items.isEmpty {
                    Text("No reminders")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.items) { item in
                        row(for: item)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }
            }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .onAppear {
                requestNotificationPermission()
            }
            .sheet(item: $itemToEdit) { item in
                EditReminderView(item: item) { title, description, date in
                    saveEditedReminder(
                        originalItem: item,
                        title: title,
                        description: description,
                        date: date
                    )
                }
            }
            .sheet(isPresented: $showingAddSheet) {
            AddReminderView {
                showConfirmation = true
                    
                Task {
                        try? await Task.sleep(for: .seconds(10))
                        showConfirmation = false
                    }
                }
            }
            .overlay(alignment: .top) {
                if showConfirmation {
                    Text("Reminder scheduled")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .padding()
                }
            }
            
    #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
    #endif
        }
    }
    @ViewBuilder
    private func row(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)

            if let details = item.details, !details.isEmpty {
                Text(details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let lat = item.lat, let lon = item.lon {
                Button("Map") {
                    openMap(lat: lat, lon: lon)
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }

            if let direction = item.direction, !direction.isEmpty {
                Label(direction, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let reminderDate = item.reminderDate {
                Label(
                    reminderDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ),
                    systemImage: "bell"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text(
                    item.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            itemToEdit = item
        }
    }
    
    private func openMap(lat: Double, lon: Double) {
        if let url = URL(
            string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)"
        ) {
            openURL(url)
        }
    }
    private func saveEditedReminder(
        originalItem: Item,
        title: String,
        description: String,
        date: Date
    ) {
        let cleanedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTitle.isEmpty else { return }
        guard date > Date() else { return }

        let cleanedDescription = description
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalDescription = cleanedDescription.isEmpty
            ? nil
            : cleanedDescription

        cancelNotification(id: originalItem.notificationID)

        let notificationID = scheduleReminder(
            title: cleanedTitle,
            description: finalDescription,
            direction: originalItem.direction,
            date: date
        )

        var updatedItem = originalItem
        updatedItem.title = cleanedTitle
        updatedItem.details = finalDescription
        updatedItem.reminderDate = date
        updatedItem.notificationID = notificationID

        store.update(item: updatedItem)
    }
}

#Preview{
    ContentView()
        .environment(ItemStore())
}
