import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error:", error)
            } else {
                print(granted ? "Notification permission granted" : "Permission denied")
            }
        }
    }

    func scheduleNotification(for med: Medication, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "ถึงเวลากินยาแล้ว"
        content.body = "\(med.name) - \(med.mealTiming)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "MEDICATION_ACTIONS"

        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date), repeats: false)

        let request = UNNotificationRequest(identifier: med.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification:", error)
            } else {
                print("Scheduled notification for \(med.name) at \(date)")
            }
        }
    }

    func rescheduleIn(minutes: Int, for id: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            guard let oldRequest = requests.first(where: { $0.identifier == id }) else { return }

            let newDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: newDate), repeats: false)

            let newRequest = UNNotificationRequest(identifier: id, content: oldRequest.content, trigger: trigger)

            UNUserNotificationCenter.current().add(newRequest) { error in
                if let error = error {
                    print("Failed to reschedule:", error)
                } else {
                    print("Rescheduled \(id) in \(minutes) minutes")
                }
            }
        }
    }

    func cancelNotification(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("Cancelled notification:", id)
    }
}
