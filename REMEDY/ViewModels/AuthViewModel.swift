import FirebaseFirestore
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userProfile: UserProfile?

    private let db = Firestore.firestore()

    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        if isLoggedIn { loadUserProfile() }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ Sign-in failed: \(error.localizedDescription)")
                return
            }

            if result != nil {
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                    self.loadUserProfile()
                    print("✅ Signed in successfully")
                }
            }
        }
    }


    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let uid = result?.user.uid {
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
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.isLoggedIn = false
        self.userProfile = nil
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                do {
                    let profile = try Firestore.Decoder().decode(UserProfile.self, from: data)
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }
    }

    func saveUserProfile(_ profile: UserProfile, uid: String? = nil) {
        guard let userID = uid ?? Auth.auth().currentUser?.uid else { return }

        do {
            try db.collection("users").document(userID).setData(from: profile, merge: true)
            self.userProfile = profile

            // ✅ Reschedule notifications after saving the profile
            let medVM = MedicationViewModel()
            medVM.rescheduleAllNotifications(with: profile)

        } catch {
            print("Saving profile error: \(error)")
        }
    }

}
