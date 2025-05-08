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
    
    private func scheduleLowPillWarningIfNeeded(for medication: Medication) {
        let dosesPerDay = max(1, medication.mealTimes.count + (medication.isBeforeSleep ? 1 : 0))
        let dailyPillUsage = medication.pillsPerDose * dosesPerDay

        guard dailyPillUsage > 0 else { return }

        let daysLeft = medication.totalPills / dailyPillUsage

        print("💊 Checking pills for \(medication.name): \(medication.totalPills) pills left, uses \(dailyPillUsage)/day → \(daysLeft) days left")

        if daysLeft == 1 {
            // ⏱ Trigger the notification immediately
            let content = UNMutableNotificationContent()
            content.title = "⚠️ ยาใกล้หมดแล้ว"
            content.body = "ยาของคุณ \(medication.name) จะหมดพรุ่งนี้!"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false) // shows in 3 sec

            let request = UNNotificationRequest(
                identifier: "\(medication.id.uuidString)_lowpill",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to trigger low-pill notification:", error)
                } else {
                    print("🚨 Low-pill alert triggered for \(medication.name)")
                }
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

            for (index, date) in reminderTimes.enumerated() {
                let identifier = "\(medication.id.uuidString)_\(index)"
                NotificationManager.shared.scheduleNotification(for: medication, at: date, identifier: identifier)
            }

            scheduleLowPillWarningIfNeeded(for: medication)


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
            scheduleLowPillWarningIfNeeded(for: updated)

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
                    let identifiers = (0..<5).map { "\(medication.id.uuidString)_\($0)" }
                    for id in identifiers {
                        NotificationManager.shared.cancelNotification(with: id)
                    }
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

        let offset = medication.mealTiming == "Before Meal" ? -30 : 30

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
