import Foundation

class SnoozeManager {
    static let shared = SnoozeManager()

    private let key = "snoozedMedications"

    private init() {}

    func isSnoozed(id: String) -> Bool {
        guard let data = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Any]],
              let info = data[id],
              let expire = info["expire"] as? Date else { return false }
        return Date() < expire
    }

    func snoozeCount(for id: String) -> Int {
        guard let data = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Any]],
              let info = data[id],
              let count = info["count"] as? Int else { return 0 }
        return count
    }

    func incrementSnooze(id: String, durationMinutes: Int) {
        var data = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Any]] ?? [:]
        let count = (data[id]?["count"] as? Int ?? 0) + 1
        data[id] = [
            "count": count,
            "expire": Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        ]
        UserDefaults.standard.set(data, forKey: key)
    }

    func clearExpired() {
        var data = UserDefaults.standard.dictionary(forKey: key) as? [String: [String: Any]] ?? [:]
        let now = Date()
        for (key, value) in data {
            if let expire = value["expire"] as? Date, expire < now {
                data.removeValue(forKey: key)
            }
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}
