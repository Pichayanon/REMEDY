import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}


#Preview {
    ContentView().environmentObject(AuthViewModel())
}
