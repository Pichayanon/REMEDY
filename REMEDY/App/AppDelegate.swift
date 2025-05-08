import UIKit
import UserNotifications
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestPermission()
        configureNotificationActions()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        switch response.actionIdentifier {
        case "TAKEN":
            print("User tapped 'Taken' for medication ID: \(id)")
            // TODO: อัปเดตว่า user กินยาแล้ว (เช่น update Firestore)
        case "SNOOZE":
            print("User tapped 'Snooze' for medication ID: \(id)")
            NotificationManager.shared.rescheduleIn(minutes: 10, for: id)
        default:
            break
        }
        completionHandler()
    }

    private func configureNotificationActions() {
        let taken = UNNotificationAction(identifier: "TAKEN", title: "ทานแล้ว", options: [.authenticationRequired])
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "เลื่อน 10 นาที", options: [])

        let category = UNNotificationCategory(
            identifier: "MEDICATION_ACTIONS",
            actions: [taken, snooze],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
