# Recordatorios 📍

App nativa de recordatorios para iPhone y Mac, desarrollada 100% en **SwiftUI**.

Proyecto creado para aprender Swift y el ecosistema de Apple, partiendo desde cero con conocimientos previos en JavaScript y C++.

## ✨ Funcionalidades principales

- **Crear recordatorios** con título, descripción opcional, fecha y hora
- **Notificaciones locales** que suenan incluso con la app cerrada
- **Búsqueda de direcciones** con geocodificación (texto → coordenadas GPS)
- **Integración con mapas**: botón para abrir la ubicación en Google Maps
- **Validación de fechas**: no permite programar recordatorios en el pasado
- **Edición completa**: modificar título, descripción, fecha y dirección
- **Borrado seguro**: al eliminar un recordatorio se cancela su notificación
- **Persistencia local**: los datos se guardan en disco (JSON) y sobreviven al cierre de la app

## 🌐 APIs REST externas (gratuitas, sin API key)

- **[Nominatim (OpenStreetMap)](https://nominatim.openstreetmap.org)**: geocodificación de direcciones (convierte texto como "Obelisco, Buenos Aires" en coordenadas GPS)

## 🏗️ Arquitectura

El proyecto sigue una arquitectura limpia con separación de responsabilidades:

| Archivo | Responsabilidad |
|---------|----------------|
| `remindersApp.swift` | Punto de entrada (`@main`), inyecta el store en el entorno |
| `ContentView.swift` | Pantalla principal, orquesta UI y llamadas a servicios |
| `EditReminderView.swift` | Pantalla de edición con patrón de borrador |
| `Item.swift` | Modelo de datos (`Codable` para persistencia JSON) |
| `ItemStore.swift` | Backend local: maneja memoria + disco + notificaciones |
| `NotificationHelper.swift` | Cliente para notificaciones locales del sistema |
| `MapaClient.swift` | Cliente para la API de mapas (geocodificación) |

### Patrones utilizados

- **@Observable**: para reactividad automática de la UI cuando cambian los datos
- **@State / @Binding**: para estado local y comunicación bidireccional con controles
- **@Environment**: para inyección de dependencias
- **Property Wrappers**: para agregar comportamiento a propiedades
- **Async/Await**: para operaciones de red sin bloquear la UI
- **Codable**: para serialización/deserialización automática a JSON

## 🚀 Cómo correr el proyecto

### Requisitos

- macOS con Xcode 16 o superior
- iPhone físico (opcional, pero recomendado) o simulador de iOS

### Pasos

1. **Clonar el repositorio**:
   ```bash
   git clone https://github.com/astradamanuel/reminders.git
   cd reminders
