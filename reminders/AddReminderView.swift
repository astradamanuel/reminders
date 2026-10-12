import SwiftUI

struct AddReminderView: View {
    
    @Environment(ItemStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var newTitle = ""
    @State private var newDescription = ""
    @State private var newDirection = ""
    @State private var selectedDate = Date().addingTimeInterval(60)
    
    @State private var resolvedDirection: String? = nil
    @State private var selectedLat: Double? = nil
    @State private var selectedLon: Double? = nil
    @State private var searchingDirection = false
    @State private var notFound = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case title
        case description
        case direction
    }
    
    private var validDate: Bool {
        selectedDate > Date()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Reminder title", text: $newTitle)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .description }
                    
                    TextField("Description (optional)", text: $newDescription, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .description)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .direction }
                    
                    HStack {
                        TextField("Place or direction (optional)", text: $newDirection)
                            .focused($focusedField, equals: .direction)
                            .submitLabel(.search)
                            .onSubmit { Task { await searchDirection() } }
                        
                        Button {
                            Task { await searchDirection() }
                        } label: {
                            if searchingDirection {
                                ProgressView()
                            } else {
                                Image(systemName: "mappin.and.ellipse")
                            }
                        }
                        .disabled(
                            newDirection
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            || searchingDirection
                        )
                    }
                    
                    if notFound {
                        Text("Location not found")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    if let name = resolvedDirection {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .lineLimit(2)
                    }
                    
                    DatePicker(
                        "Date and time",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Button("Schedule", action: addItem)
                        .disabled(
                            newTitle
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            || !validDate
                        )
                }
            }
            .navigationTitle("New reminder")
            
            
#if os(macOS)
            .frame(minWidth: 400, minHeight: 450)
#endif
        }
    }
    
    private func searchDirection() async {
        let text = newDirection
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else { return }
        
        searchingDirection = true
        notFound = false
        
        do {
            let result = try await MapClient().searchDirection(text)
            
            resolvedDirection = result?.name
            selectedLat = result?.lat
            selectedLon = result?.lon
            notFound = result == nil
        } catch {
            print("Error searching direction:", error)
            resolvedDirection = nil
            selectedLat = nil
            selectedLon = nil
            notFound = true
        }
        
        searchingDirection = false
    }
    
    
    private func addItem() {
        let title = newTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !title.isEmpty else { return }
        guard validDate else { return }
        
        let notificationID = scheduleReminder(
            title: title,
            description: newDescription,
            direction: resolvedDirection,
            date: selectedDate
        )
        
        scheduleSuccessNotification()
        
        store.add(
            title: title,
            description: newDescription,
            direction: resolvedDirection,
            lat: selectedLat,
            lon: selectedLon,
            date: selectedDate,
            notificationID: notificationID
        )
        
        dismiss()
        
        newTitle = ""
        newDescription = ""
        newDirection = ""
        resolvedDirection = nil
        selectedLat = nil
        selectedLon = nil
        notFound = false
        focusedField = nil
    }
}

#Preview {
    AddReminderView()
        .environment(ItemStore())
}
