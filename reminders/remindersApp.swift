//
//  remindersApp.swift
//  reminders
//  arranca la app, crea el store, inyecta el cerebro, muestra la primera ventana.

import SwiftUI

@main
struct RemindersApp: App { // struct: fotocopia de datos // : App cumple protocolo App, que te obliga a tener un body y que devuelva una Scene

    @State private var store = ItemStore() // = ItemStore() → acá nace el cerebro de la app

    var body: some Scene { // Una Scene es como un “contenedor de ventanas”. Una View es lo que se ve adentro.
        WindowGroup {
            ContentView() // Crea la pantalla principal
                .environment(store) // inyecta el store en el entorno.
        }
    }
}
// tema .enviroment(store)
// Esto es lo que hace posible que, en cualquier vista de adentro, alguien escriba:
// @Environment(ItemStore.self) private var store
// y lo reciba. Es como dejar el cerebro en un lugar público donde todas las vistas pueden enchufarse.

// Resumen de la app
// Persistencia local: Usás FileManager, JSONEncoder y JSONDecoder para que los datos sobrevivan al cierre de la app (ItemStore).
// Notificaciones del Sistema: Usás UNUserNotificationCenter para agendar alertas que suenan incluso con la app cerrada (NotificationHelper).
// Consumo de API REST: Usás URLSession con async/await para traer datos reales de internet (MapaClient).
// Geolocalización y Mapas: Convertís texto a coordenadas y abrís rutas en el mapa del dispositivo.
// UI Declarativa (SwiftUI): Dejaste de lado el "dibujar a mano" (como en UIKit o C++ con Qt) para pasar a describir la UI en función del estado (@State, @Observable).
// Arquitectura limpia: Separaste la vista (ContentView), el modelo (Item), el controlador de datos (ItemStore) y los servicios externos (MapaClient, NotificationHelper).
