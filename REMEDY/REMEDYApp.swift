import SwiftUI
import FirebaseCore

@main
struct REMEDYApp: App {
    @StateObject var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
        }
    }
}

