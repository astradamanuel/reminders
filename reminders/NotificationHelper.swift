//
//  NotificationHelper.swift → el que habla con el sistema de notificaciones
//  solamente funciones sueltas
//  solo arma pedidos y se los pasa al sistema.
// el patron que se repite
// 1. UNMutableNotificationContent  → el QUÉ (título, cuerpo, sonido)
// 2. UN...Trigger                  → el CUÁNDO
// 3. UNNotificationRequest         → el ticket que junta todo + ID
// 4. center.add(request)           → entregarlo al sistema

import UserNotifications // UN = user notifications

func pedirPermisoNotificaciones() {
    UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound]
    ) { granted, error in
        if let error {
            print("Error de permiso:", error)
        }

        print("Permiso concedido:", granted)
    }
}

func programarNotificacionEn(segundos: Int) {
    let content = UNMutableNotificationContent() // representa lo que se ve y se escucha: título, cuerpo, sonido.
    content.title = "Prueba"
    content.body = "Esta notificación tiene sonido"
    content.sound = .default // Acá no ponemos UNNotificationSound.default completo porque Swift ya sabe el tipo:
                            //  se puede escribir solo .default. Eso se llama inferencia por contexto.
    let trigger = UNTimeIntervalNotificationTrigger( // trigger = "el cuando"
        timeInterval: TimeInterval(segundos),
        repeats: false
    )

    let request = UNNotificationRequest( // el ticket que junta todo
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error {
            print("Error al programar notificación:", error)
        } else {
            print("Notificación programada")
        }
    }
}

func programarNotificacionExito() {
    let content = UNMutableNotificationContent()
    content.title = "Recordatorio programado"
    content.body = "Tu recordatorio se guardó correctamente."
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: 10,
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error {
            print("Error al programar notificación de éxito:", error)
        } else {
            print("Notificación de éxito programada")
        }
    }
}

func programarRecordatorio(
    titulo: String,
    descripcion: String?,
    direccion: String?,
    fecha: Date
    ) -> String {
    let notificationID = UUID().uuidString

    let content = UNMutableNotificationContent()
    content.title = titulo

    var bodyFinal = "Tenés un recordatorio."

    if let bodyText = descripcion?.trimmingCharacters(in: .whitespacesAndNewlines),
       !bodyText.isEmpty {
        bodyFinal = bodyText
    }

    if let direccion = direccion, !direccion.isEmpty {
        bodyFinal += "\n📍 \(direccion)"
    }

    content.body = bodyFinal
    content.sound = .default

    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: fecha
    )

    let trigger = UNCalendarNotificationTrigger(
        dateMatching: components,
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: notificationID,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error {
            print("Error al programar recordatorio:", error)
        } else {
            print("Recordatorio programado para:", fecha)
        }
    }

    return notificationID
}
func cancelarNotificacion(id: String?) {
    guard let id = id else {
        return
    }

    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(
            withIdentifiers: [id]
        )
}


