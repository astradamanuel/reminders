import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound]
    ) { granted, error in
        if let error {
            print("Permission error:", error)
        }

        print("Permission granted:", granted)
    }
}

func scheduleNotification(seconds: Int) {
    let content = UNMutableNotificationContent()
    content.title = "Test"
    content.body = "This notification has sound"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: TimeInterval(seconds),
        repeats: false
    )

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error {
            print("Error scheduling notification:", error)
        } else {
            print("Notification scheduled")
        }
    }
}



func scheduleReminder(
    title: String,
    description: String?,
    direction: String?,
    date: Date
) -> String {
    let notificationID = UUID().uuidString

    let content = UNMutableNotificationContent()
    content.title = title

    var finalBody = "You have a reminder."

    if let bodyText = description?.trimmingCharacters(in: .whitespacesAndNewlines),
       !bodyText.isEmpty {
        finalBody = bodyText
    }

    if let direction = direction, !direction.isEmpty {
        finalBody += "\n📍 \(direction)"
    }

    content.body = finalBody
    content.sound = .default

    let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute],
        from: date
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
            print("Error scheduling reminder:", error)
        } else {
            print("Reminder scheduled for:", date)
        }
    }

    return notificationID
}

func cancelNotification(id: String?) {
    guard let id = id else {
        return
    }

    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(
            withIdentifiers: [id]
        )
}
