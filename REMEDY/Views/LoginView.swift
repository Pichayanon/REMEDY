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
                .autocapitalization(.none)
                .disableAutocorrection(true)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

                if isSignUp {
                    authVM.signUp(email: cleanEmail, password: cleanPassword)
                } else {
                    authVM.signIn(email: cleanEmail, password: cleanPassword)
                }
            }) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                isSignUp.toggle()
            }) {
                Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .padding()
    }
}
