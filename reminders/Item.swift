import Foundation

struct Item: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var details: String? = nil
    var direction: String? = nil
    var lat: Double? = nil
    var lon: Double? = nil
    var createdAt = Date()
    var reminderDate: Date? = nil
    var notificationID: String? = nil
}
