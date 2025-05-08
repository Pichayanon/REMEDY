import FirebaseFirestore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()

    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        if isLoggedIn {
            loadUserProfile()
        }
    }

    func signIn(email: String, password: String) {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            self.errorMessage = "Email and password must not be empty."
            return
        }

        Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            DispatchQueue.main.async {
                self.isLoggedIn = true
                self.loadUserProfile()
            }
        }
    }


    func signUp(email: String, password: String) {
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let uid = result?.user.uid else { return }

            DispatchQueue.main.async {
                self.isLoggedIn = true

                let defaultProfile = UserProfile(
                    name: "",
                    breakfastTime: Date(),
                    lunchTime: Date(),
                    dinnerTime: Date(),
                    sleepTime: Date()
                )

                self.saveUserProfile(defaultProfile, uid: uid)
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.userProfile = nil
            self.errorMessage = nil
        }
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                }
                return
            }

            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                do {
                    let profile = try Firestore.Decoder().decode(UserProfile.self, from: data)
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to decode profile: \(error.localizedDescription)"
                    }
                }
            } else {
                let defaultProfile = UserProfile(
                    name: "",
                    breakfastTime: Date(),
                    lunchTime: Date(),
                    dinnerTime: Date(),
                    sleepTime: Date()
                )
                self.saveUserProfile(defaultProfile)
            }
        }
    }

    func saveUserProfile(_ profile: UserProfile, uid: String? = nil) {
        guard let userID = uid ?? Auth.auth().currentUser?.uid else { return }

        do {
            try db.collection("users").document(userID).setData(from: profile, merge: true)
            DispatchQueue.main.async {
                self.userProfile = profile
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
            }
        }
    }
}
