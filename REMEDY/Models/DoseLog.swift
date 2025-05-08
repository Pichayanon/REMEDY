import Foundation

struct DoseLog: Identifiable, Codable {
    var id: UUID = UUID()
    var medicationID: UUID
    var medicationName: String
    var date: Date
    var meal: String
    var isTaken: Bool
}
