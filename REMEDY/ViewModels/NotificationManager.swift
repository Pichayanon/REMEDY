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

    func scheduleNotification(for med: Medication, at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Take Your Medication"
        content.body = "\(med.name) - \(med.mealTiming)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "MEDICATION_ACTIONS"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification:", error)
            } else {
                print("✅ Scheduled notification for \(med.name) [\(identifier)] at \(date)")
            }
        }
    }


    func rescheduleIn(minutes: Int, for id: String) {
        let newDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "This is your 10-minute snooze reminder to take your medication"
        content.sound = .defaultCritical
        content.categoryIdentifier = "MEDICATION_ACTIONS"

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: newDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to reschedule manually:", error)
            } else {
                print("✅ Manually scheduled reminder for ID: \(id) in \(minutes) minutes")
            }
        }
    }


    func cancelNotification(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("Cancelled notification:", id)
    }
    
    func scheduleLowPillWarning(for med: Medication, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Low Medication Alert"
        content.body = "Your medication \(med.name) will run out tomorrow. Don’t forget to prepare a refill!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(med.id.uuidString)_lowpill",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule low pill warning:", error)
            } else {
                print("⚠️ Low pill warning scheduled for \(med.name) at \(date)")
            }
        }
    }

}
