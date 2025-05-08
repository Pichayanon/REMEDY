import Foundation
import FirebaseFirestore
import FirebaseAuth

class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []

    private let db = Firestore.firestore()

    init() {
        loadMedications()
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

    func addMedication(_ medication: Medication, userProfile: UserProfile) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            try db.collection("users").document(uid).collection("medications")
                .document(medication.id.uuidString)
                .setData(from: medication)

            let reminderTimes = calculateReminderTimes(for: medication, from: userProfile)
            for date in reminderTimes {
                NotificationManager.shared.scheduleNotification(for: medication, at: date)
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

            NotificationManager.shared.cancelNotification(with: updated.id.uuidString)

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
                } else {
                    NotificationManager.shared.cancelNotification(with: medication.id.uuidString)
                }
            }
    }

    private func calculateReminderTimes(for medication: Medication, from profile: UserProfile) -> [Date] {
        var times: [Date] = []

        func adjustedTime(from base: Date, offset: Int) -> Date {
            return Calendar.current.date(byAdding: .minute, value: offset, to: base) ?? base
        }

        if medication.isBeforeSleep {
            times.append(adjustedTime(from: profile.sleepTime, offset: -30))
        }

        let offset = medication.mealTiming == "Before" ? -30 : 30

        for meal in medication.mealTimes {
            switch meal {
            case "Breakfast":
                times.append(adjustedTime(from: profile.breakfastTime, offset: offset))
            case "Lunch":
                times.append(adjustedTime(from: profile.lunchTime, offset: offset))
            case "Dinner":
                times.append(adjustedTime(from: profile.dinnerTime, offset: offset))
            default:
                break
            }
        }

        return times
    }
}
