import SwiftUI
import FirebaseCore
import UserNotifications

@main
struct REMEDYApp: App {
    init() {
        FirebaseApp.configure()
        requestNotificationPermission()
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared  // 👈 This makes notifications appear in foreground
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }


    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
