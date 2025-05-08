import SwiftUI
import Firebase

@main
struct REMEDYApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authVM: AuthViewModel?

    init() {
        FirebaseApp.configure()
        _authVM = State(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            if let authVM = authVM {
                ContentView()
                    .environmentObject(authVM)
            } else {
                ProgressView()
            }
        }
    }
}
