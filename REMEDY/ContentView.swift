import SwiftUI

struct ContentView: View {
    @StateObject var authVM = AuthViewModel()

    var body: some View {
        if authVM.isLoggedIn {
            HomeView()
                .environmentObject(authVM)
        } else {
            LoginView()
                .environmentObject(authVM)
        }
    }
}


#Preview {
    ContentView()
}
