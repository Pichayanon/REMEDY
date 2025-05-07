import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
        .environmentObject(AuthViewModel())
}
