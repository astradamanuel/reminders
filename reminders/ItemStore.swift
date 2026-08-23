//
// ItemStore.swift → el cerebro que guarda y administra los datos
// Guarda la lista en memoria (para que la pantalla la muestre rápido).
// Guarda la lista en disco (para que no se pierda al cerrar la app).
// Administra los recordatorios: agregar, editar, borrar, ordenar.
//

import SwiftUI
import Observation
import UserNotifications // para cancelar notificaciones pendientes al borrar

@Observable // avisa a SwiftUI cuando algo cambia // vigilá las propiedades; si alguna cambia, avisale a las vistas para que se redibujen
final class ItemStore { // final = nadie puede heredar de esta clase // class tipo de referencia: todos comparten el mismo cerebro (si fuera struct, cada vista tendría su copia)

    private let persistenceEnabled = true // interruptor de persistencia

    var items: [Item] = [] // [Item] array de Item y en cuanto a [] arranca vacio (despues load() lo llena desde el disco).

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
        direccion: String?,
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
            direccion: direccion,
            lat: lat,
            lon: lon,
            reminderDate: date,
            notificationID: notificationID
        )

        items.append(item) // append → lo mete en memoria.
        sortItems() // ordena por fecha.
        save() // guarda
    }
    
    func update(item updatedItem: Item) { // por dentro la variable se llama updatedItem.
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) { //closure
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

    func load() { //  disco → memoria
        guard persistenceEnabled else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            items = try decoder.decode([Item].self, from: data) // “convertime estos bytes en un array de Item”. [Item].self = “el tipo array-de-Item, como valor”. Funciona porque Item es Codable.
            sortItems()
        } catch {
            items = [] // si falló (archivo inexistente o roto), arrancamos vacíos sin crashear.
        }
    }

    private func save() { // memoria → disco
        guard persistenceEnabled else {
            return
        }

        do {
            let encoder = JSONEncoder() // traductor inverso: objetos → JSON
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(items) // Convierte todo el array a bytes JSON.

            try data.write(
                to: fileURL,
                options: [.atomic, .completeFileProtection]
            )
        } catch {
            print("Error al guardar:", error)
        }
    }

    private func sortItems() { // ordenar
        items.sort { first, second in
            let firstDate = first.reminderDate ?? first.createdAt
            // ?? Si el recordatorio tiene fecha de recordatorio,
            // usá esa. Si no, usá la fecha de creación
            let secondDate = second.reminderDate ?? second.createdAt

            return firstDate < secondDate
        }
    }
}
