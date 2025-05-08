import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 16) {
            Text(isSignUp ? "Create Account" : "Login")
                .font(.largeTitle.bold())
                .padding(.bottom, 16)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

//            if let error = authVM.errorMessage {
//                Text(error)
//                    .foregroundColor(.red)
//                    .font(.caption)
//            }

            Button(isSignUp ? "Sign Up" : "Login") {
                if isSignUp {
                    authVM.signUp(email: email, password: password)
                } else {
                    authVM.signIn(email: email, password: password)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up") {
                isSignUp.toggle()
            }
            .font(.caption)
            .foregroundColor(.blue)

            Spacer()
        }
        .padding()
    }
}
