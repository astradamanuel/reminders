//
//  Item.swift → la forma de los datos (el modelo)
//  define la “ficha” de un recordatorio: título, descripción, lugar (texto + coordenadas), fechas e ID de notificación. Todo lo demás del programa gira alrededor de esta ficha.

import Foundation // (#include c++ o jv) te permite usar UUID, date, entre otros

struct Item: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var details: String? = nil
    var direccion: String? = nil
    var lat: Double? = nil // con esto se arma las coordenadas para armar el link de Google Maps.
    var lon: Double? = nil
    var createdAt = Date()
    var reminderDate: Date? = nil
    var notificationID: String? = nil
}

// struct = fotocopia de un documento
// class = documento original

// este tipo "Item" promete cumplir estos contratos/protocolos
// Identifiable = Tenés que tener una propiedad llamada id que sea única.
// Codable = Encodable → puedo convertir el objeto a datos (por ejemplo JSON).
//           Decodable → puedo reconstruir el objeto desde datos.
// Hashable = Puedo compararme con otros y puedo generar un código de hash.

// MyApp crea el store
// ↓
// .environment(store) lo inyecta en el entorno
// ↓
// ContentView lo pesca con @Environment
// ↓
// la lista se dibuja con store.items
