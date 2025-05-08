import Foundation
import FirebaseFirestore
import FirebaseAuth

class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []

    private let db = Firestore.firestore()

    init() {
        loadMedications()
    }
    
    func computeReminderTimes(for medication: Medication, userProfile: UserProfile) -> [DateComponents] {
        func adjustedTime(from base: Date, offset: Int) -> DateComponents {
            let adjusted = Calendar.current.date(byAdding: .minute, value: offset, to: base)!
            return Calendar.current.dateComponents([.hour, .minute], from: adjusted)
        }

        var reminderTimes: [DateComponents] = []

        for meal in medication.mealTimes {
            switch meal {
            case "Breakfast":
                reminderTimes.append(adjustedTime(from: userProfile.breakfastTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            case "Lunch":
                reminderTimes.append(adjustedTime(from: userProfile.lunchTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            case "Dinner":
                reminderTimes.append(adjustedTime(from: userProfile.dinnerTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            default:
                break
            }
        }

        if medication.isBeforeSleep {
            reminderTimes.append(adjustedTime(from: userProfile.sleepTime, offset: -30))
        }

        return reminderTimes
    }

    
    private func fetchUserProfile(completion: @escaping (UserProfile?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        let docRef = db.collection("users").document(uid)
        docRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("User profile not found")
                completion(nil)
                return
            }

            do {
                let profile = try document.data(as: UserProfile.self)
                completion(profile)
            } catch {
                print("Failed to decode user profile: \(error)")
                completion(nil)
            }
        }
    }
    
    


    func loadMedications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("medications")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading medications: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                self.medications = documents.compactMap { doc -> Medication? in
                    try? doc.data(as: Medication.self)
                }
            }
    }
    
    private func scheduleNotifications(for medication: Medication, userProfile: UserProfile) {
        func adjustedTime(base: Date, offset: Int) -> DateComponents {
            let adjusted = Calendar.current.date(byAdding: .minute, value: offset, to: base)!
            return Calendar.current.dateComponents([.hour, .minute], from: adjusted)
        }

        var reminderTimes: [DateComponents] = []

        for meal in medication.mealTimes {
            switch meal {
            case "Breakfast":
                reminderTimes.append(adjustedTime(base: userProfile.breakfastTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            case "Lunch":
                reminderTimes.append(adjustedTime(base: userProfile.lunchTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            case "Dinner":
                reminderTimes.append(adjustedTime(base: userProfile.dinnerTime, offset: medication.mealTiming == "Before" ? -30 : 30))
            default: break
            }
        }

        if medication.isBeforeSleep {
            reminderTimes.append(adjustedTime(base: userProfile.sleepTime, offset: -30))
        }

        for (index, time) in reminderTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Medicine Reminder"
            content.body = "Time to take \(medication.name)"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(medication.id.uuidString)_\(index)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Notification error: \(error)")
                }
            }
        }
    }
    
    func testImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔔 Test Notification"
        content.body = "This is a test. Notifications work!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification failed: \(error)")
            } else {
                print("✅ Test notification scheduled for 10 seconds from now")
            }
        }
    }



    func addMedication(_ medication: Medication) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            _ = try db.collection("users").document(uid).collection("medications")
                .document(medication.id.uuidString)
                .setData(from: medication)

            // 🔽 Fetch the user's profile and schedule notifications
            fetchUserProfile { profile in
                if let profile = profile {
                    // 🔁 Calculate the times
                    let times = self.computeReminderTimes(for: medication, userProfile: profile)

                    // 🖨 Print each scheduled time for debugging
                    for (index, components) in times.enumerated() {
                        if let hour = components.hour, let minute = components.minute {
                            print("🔔 Scheduled \(medication.name) at \(String(format: "%02d", hour)):\(String(format: "%02d", minute)) [\(index)]")
                        }
                    }

                    // 🧠 Then schedule
                    self.scheduleNotifications(for: medication, userProfile: profile)
                }
            }


        } catch {
            print("Error saving medication: \(error)")
        }
    }


    func markAsTaken(medication: Medication) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var updated = medication
        updated.totalPills = max(0, updated.totalPills - updated.pillsPerDose)

        do {
            try db.collection("users").document(uid).collection("medications")
                .document(updated.id.uuidString)
                .setData(from: updated)
        } catch {
            print("Error updating medication: \(error)")
        }
    }

    func deleteMedication(_ medication: Medication) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("medications")
            .document(medication.id.uuidString)
            .delete { error in
                if let error = error {
                    print("Error deleting medication: \(error)")
                }
            }
    }
    
    func rescheduleAllNotifications(with updatedProfile: UserProfile) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("medications").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Failed to load medications for rescheduling")
                return
            }

            let medications = documents.compactMap { try? $0.data(as: Medication.self) }

            for medication in medications {
                // Cancel old notifications
                let identifiers = (0..<5).map { "\(medication.id.uuidString)_\($0)" }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

                // Reschedule with new times
                self.scheduleNotifications(for: medication, userProfile: updatedProfile)
            }
        }
    }
    
    

}
