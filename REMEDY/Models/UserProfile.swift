import Foundation

struct UserProfile: Codable {
    var name: String
    var breakfastTime: Date
    var lunchTime: Date
    var dinnerTime: Date
    var sleepTime: Date
}
