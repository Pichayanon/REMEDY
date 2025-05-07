import Foundation

struct Medication: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var mealTiming: String
    var mealTimes: [String]
    var isBeforeSleep: Bool
    var totalPills: Int
    var pillsPerDose: Int
}
