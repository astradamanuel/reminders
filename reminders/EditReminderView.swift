import SwiftUI

struct EditReminderView: View {

    @Environment(\.dismiss) private var dismiss

    let item: Item
    let onSave: (String, String, Date) -> Void

    @State private var title = ""
    @State private var details = ""
    @State private var date = Date()
    @State private var showDateError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .autocorrectionDisabled()
                    TextField("Description (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section {
                    DatePicker(
                        "Date and time",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("Edit reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if date <= Date() {
                            showDateError = true
                        } else {
                            onSave(title, details, date)
                            dismiss()
                        }
                    }
                    .disabled(
                        title
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
            .alert(
                "Invalid date",
                isPresented: $showDateError
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The date cannot be in the past.")
            }
            .onAppear {
                title = item.title
                details = item.details ?? ""
                date = item.reminderDate ?? item.createdAt
            }
        }
        
        
#if os(macOS)
        .frame(minWidth: 400, minHeight: 350)
#endif
        }
    }

#Preview {
    EditReminderView(item: Item(title: "Manu", details: "Hoy", reminderDate: Date())) { newTitle, newDetails, newreminderDate in
    }
        .environment(ItemStore())
}
