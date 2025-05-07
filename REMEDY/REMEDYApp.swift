import SwiftUI
import FirebaseCore

@main
struct REMEDYApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
