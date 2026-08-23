//
//  ContentView.swift → la pantalla principal
//
// Este archivo no guarda datos en disco ni habla con internet directamente. Su trabajo es orquestar:
// Escuchar al usuario (tecleos, toques)
// Pedirle cosas al MapaClient (internet)
// Pedirle cosas al NotificationHelper (sistema)
// Mandarle todo al ItemStore (el cerebro/disco)
// Redibujarse solo cuando el ItemStore cambia

// $newTitle es un Binding . Le dice al TextField: "Si el usuario escribe, actualizá newTitle. Y si newTitle cambia por código, actualizá el TextField

import SwiftUI

struct ContentView: View { // : View significa que cumple el protocolo View. Ese protocolo solo te exige una cosa: que tengas una propiedad llamada body que devuelva otra vista.

    @Environment(ItemStore.self) private var store // Es un Property Wrapper, las palabras que empiezan con @ son macros o envoltorios que le agregan "superpoderes" a una variable. Buscá en el entorno de la app si alguien inyectó un ItemStore y conectámelo acá
    @Environment(\.openURL) private var openURL // \.openURL → Una acción del sistema. Es una función que, si le pasás una URL (como la de Google Maps), la abre en el navegador o en la app de Mapas

    @State private var newTitle = "" //// @State Son variables que, si cambian, SwiftUI redibuja la pantalla automáticamente.
    @State private var newDescription = ""
    @State private var newDireccion = ""
    @State private var selectedDate = Date().addingTimeInterval(60)
    @State private var itemToEdit: Item? // itemToEdit es un Item? (opcional). Si es nil, no hay nada que editar. Si tiene un Item, se abre la pantalla de edición. Es el interruptor del sheet.

    @State private var direccionResuelta: String? = nil // Estos 5 son exclusivamente para manejar la API de mapas:
    @State private var latSeleccionado: Double? = nil
    @State private var lonSeleccionado: Double? = nil
    @State private var buscandoDireccion = false
    @State private var noSeEncontro = false

    // @FocusState es un "puntero" que sabe qué campo tiene el teclado activo ahora.
    // Se usa para saltar entre campos con la tecla "return".
    @FocusState private var campoFocado: Campo?

    // Enum para identificar cada campo del formulario
    private enum Campo {
        case titulo
        case descripcion
        case direccion
    }

    private var fechaValida: Bool {
        selectedDate > Date()
    }

    var body: some View {
        NavigationStack {
            // Cambiamos de VStack a List: toda la pantalla es scrolleable.
            // Esto hace que en iPhone el teclado empuje el contenido sin tapar nada.
            List {
                // Section agrupa campos relacionados con un encabezado
                Section("Nuevo recordatorio") {
                    TextField("Título del recordatorio", text: $newTitle) // El símbolo $ crea un Binding (enlace de doble vía). Si el usuario escribe, newTitle cambia. Si newTitle cambia por código, el texto en pantalla se borra.
                        .focused($campoFocado, equals: .titulo) // Conecta este campo con el FocusState
                        .submitLabel(.next) // Cambia la tecla "return" del teclado a "siguiente"
                        .onSubmit { campoFocado = .descripcion } // Al tocar return, salta a descripción

                    TextField("Descripción (opcional)", text: $newDescription, axis: .vertical)
                        .lineLimit(1...3)
                        .focused($campoFocado, equals: .descripcion)
                        .submitLabel(.next)
                        .onSubmit { campoFocado = .direccion }

                    HStack {
                        TextField("Lugar o dirección (opcional)", text: $newDireccion)
                            .focused($campoFocado, equals: .direccion)
                            .submitLabel(.search) // Cambia la tecla a "buscar"
                            .onSubmit { Task { await buscarDireccion() } } // Al tocar return, busca el mapa

                        Button {
                            Task { await buscarDireccion() } // Los botones normales no pueden ser async (no pueden "esperar"). Task es la forma de decirle a Swift: "Arrancá una tarea paralela que sí pueda esperar a la red".
                        } label: {
                            if buscandoDireccion {
                                ProgressView()
                            } else {
                                Image(systemName: "mappin.and.ellipse")
                            }
                        }
                        .disabled(
                            newDireccion
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            || buscandoDireccion
                        )
                    }

                    if noSeEncontro {
                        Text("No se encontró el lugar")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if let nombre = direccionResuelta {
                        Text(nombre)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .lineLimit(2)
                    }

                    DatePicker(
                        "Fecha y hora",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Button("Programar", action: addItem)
                        .disabled(
                            newTitle
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            || !fechaValida
                        )
                }

                // Segunda sección: la lista de recordatorios existentes
                Section("Tus recordatorios") {
                    if store.items.isEmpty {
                        Text("No hay recordatorios")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.items) { item in
                            fila(for: item)
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("Recordatorios")
            .onAppear {
                pedirPermisoNotificaciones()
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
            // Compilación condicional: esto solo se aplica en iOS, no en Mac
            // Hace que el título "Recordatorios" sea más chico en iPhone
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // Función separada para dibujar cada fila de la lista
    // @ViewBuilder permite devolver "alguna vista" sin especificar el tipo exacto
    @ViewBuilder
    private func fila(for item: Item) -> some View {
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
                Button("Mapa") {
                    abrirMapa(lat: lat, lon: lon)
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }

            if let direccion = item.direccion, !direccion.isEmpty {
                Label(direccion, systemImage: "mappin.and.ellipse")
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

    private func buscarDireccion() async {
        let texto = newDireccion
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !texto.isEmpty else { return }

        buscandoDireccion = true
        noSeEncontro = false

        do {
            let resultado = try await MapaClient().buscarDireccion(texto)

            direccionResuelta = resultado?.nombre
            latSeleccionado = resultado?.lat
            lonSeleccionado = resultado?.lon
            noSeEncontro = resultado == nil
        } catch {
            print("Error al buscar dirección:", error)
            direccionResuelta = nil
            latSeleccionado = nil
            lonSeleccionado = nil
            noSeEncontro = true
        }

        buscandoDireccion = false
    }

    private func abrirMapa(lat: Double, lon: Double) {
        if let url = URL(
            string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)"
        ) {
            openURL(url)
        }
    }

    private func addItem() {
        let title = newTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else { return }
        guard fechaValida else { return }

        let notificationID = programarRecordatorio(
            titulo: title,
            descripcion: newDescription,
            direccion: direccionResuelta,
            fecha: selectedDate
        )

        programarNotificacionExito()

        store.add(
            title: title,
            description: newDescription,
            direccion: direccionResuelta,
            lat: latSeleccionado,
            lon: lonSeleccionado,
            date: selectedDate,
            notificationID: notificationID
        )

        newTitle = ""
        newDescription = ""
        newDireccion = ""
        direccionResuelta = nil
        latSeleccionado = nil
        lonSeleccionado = nil
        noSeEncontro = false
        campoFocado = nil // Cierra el teclado después de programar
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

        cancelarNotificacion(id: originalItem.notificationID)

        let notificationID = programarRecordatorio(
            titulo: cleanedTitle,
            descripcion: finalDescription,
            direccion: originalItem.direccion,
            fecha: date
        )

        var updatedItem = originalItem
        updatedItem.title = cleanedTitle
        updatedItem.details = finalDescription
        updatedItem.reminderDate = date
        updatedItem.notificationID = notificationID

        store.update(item: updatedItem)
    }
}
