//
//  MapaClient.swift
// Este archivo hace una sola cosa: agarrar un texto como “Obelisco, Buenos Aires” y convertirlo en:
// un nombre completo y prolijo,
// una latitud,
// una longitud.
// Usando la API gratuita de OpenStreetMap (Nominatim).

// viaje completo
// texto tuyo → URL con parámetros → internet → JSON crudo
// → LugarDTO (formato de la API) → ResultadoBusqueda (formato tuyo)

import Foundation

struct LugarDTO: Decodable { // Data Transfer Object, Es un struct que existe solo para recibir lo que manda la API, con sus rarezas incluidas.
    let lat: String
    let lon: String
    let display_name: String
}

struct ResultadoBusqueda { // modelo interno
    let nombre: String
    let lat: Double
    let lon: Double
}

// la idea de tener 2
// LugarDTO         → espejo feo de la API (lat como String)
// ResultadoBusqueda → tu modelo lindo (lat como Double)
// Si mañana cambiás de API, solo tocás el DTO y la traducción. El resto de la app ni se entera.

struct MapaClient { // Un struct sin propiedades, que solo agrupa una función

    func buscarDireccion(_ texto: String) async throws -> ResultadoBusqueda? {

        var components = URLComponents(
            string: "https://nominatim.openstreetmap.org/search"
        )!

        components.queryItems = [
            URLQueryItem(name: "q", value: texto),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(
            "RecordatoriosApp/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, _) = try await URLSession.shared.data(for: request)

        if let textoJSON = String(data: data, encoding: .utf8) {
            print("Respuesta del mapa:", textoJSON)
        }

        let lugares = try JSONDecoder().decode([LugarDTO].self, from: data)

        guard let primero = lugares.first,
              let lat = Double(primero.lat),
              let lon = Double(primero.lon) else {
            return nil
        }

        return ResultadoBusqueda(
            nombre: primero.display_name,
            lat: lat,
            lon: lon
        )
    }
}

