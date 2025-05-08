import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(isSignUp ? "Create an Account" : "Welcome Back")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    CustomInputField(icon: "envelope", placeholder: "Email", text: $email)
                    CustomInputField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                }

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, -10)
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
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }

                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

struct CustomInputField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .autocapitalization(.none)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
