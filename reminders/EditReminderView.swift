//
//  EditReminderView.swift → la pantalla para editar
//
// Es el recordatorio que ContentView nos pasa al abrir el sheet
// esta vista no guarda nada ella misma

// 1. Al abrir, copiamos los datos reales a estos borradores.
// 2. El usuario manosea los borradores.
// 3. Si guarda → mandamos los borradores por onSave.
// 4. Si cancela → los borradores mueren con el sheet y nadie se entera.

import SwiftUI

struct EditReminderView: View {

    @Environment(\.dismiss) private var dismiss

    let item: Item
    let onSave: (String, String, Date) -> Void

    @State private var title = ""
    @State private var details = ""
    @State private var date = Date()
    @State private var mostrarErrorFecha = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Título") {
                    TextField("Título", text: $title)
                        .autocorrectionDisabled()
                }

                Section("Descripción") {
                    TextField("Descripción (opcional)", text: $details, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Fecha y hora") {
                    DatePicker(
                        "Fecha y hora",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("Editar recordatorio")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if date <= Date() {
                            mostrarErrorFecha = true
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
                "Fecha inválida",
                isPresented: $mostrarErrorFecha
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("La fecha no puede estar en el pasado.")
            }
            .onAppear {
                title = item.title
                details = item.details ?? ""
                date = item.reminderDate ?? item.createdAt
            }
        }
    }
}
