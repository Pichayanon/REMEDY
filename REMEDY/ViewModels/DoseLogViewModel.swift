import Foundation
import FirebaseFirestore
import FirebaseAuth

class DoseLogViewModel: ObservableObject {
    @Published var logs: [DoseLog] = []

    private let db = Firestore.firestore()

    init() {
        loadLogs()
    }

    func loadLogs() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("doseLogs")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error loading dose logs:", error?.localizedDescription ?? "")
                    return
                }

                self.logs = documents.compactMap { doc in
                    try? doc.data(as: DoseLog.self)
                }
            }
    }

    func addLog(medication: Medication, meal: String, date: Date = Date()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let log = DoseLog(
            medicationID: medication.id,
            medicationName: medication.name,
            date: date,
            meal: meal,
            isTaken: true
        )

        do {
            try db.collection("users").document(uid).collection("doseLogs")
                .document(log.id.uuidString)
                .setData(from: log)
            print("Dose log saved")
        } catch {
            print("Failed to save dose log:", error.localizedDescription)
        }
    }

    func markMissedDose(medication: Medication, meal: String, date: Date) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let log = DoseLog(
            medicationID: medication.id,
            medicationName: medication.name,
            date: date,
            meal: meal,
            isTaken: false
        )

        do {
            try db.collection("users").document(uid).collection("doseLogs")
                .document(log.id.uuidString)
                .setData(from: log)
            print("Missed dose logged")
        } catch {
            print("Failed to log missed dose:", error.localizedDescription)
        }
    }
    
    func checkAndMarkMissedDoses(for medications: [Medication], profile: UserProfile) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")!

        let now = Date()
        let today = calendar.startOfDay(for: now)

        for meal in ["Breakfast", "Lunch", "Dinner", "Sleep"] {
            let meds = medications.filter {
                $0.mealTimes.contains(meal) || (meal == "Sleep" && $0.isBeforeSleep)
            }

            for med in meds {
                let alreadyLogged = logs.contains {
                    $0.medicationID == med.id &&
                    $0.meal == meal &&
                    calendar.isDate($0.date, inSameDayAs: today)
                }

                let mealEnd = getMealEndTime(for: meal, profile: profile, calendar: calendar)

                if !alreadyLogged && now > mealEnd {
                    markMissedDose(medication: med, meal: meal, date: now)
                }
            }
        }
    }

    private func getMealEndTime(for meal: String, profile: UserProfile, calendar: Calendar) -> Date {
        switch meal {
        case "Breakfast": return profile.lunchTime
        case "Lunch": return profile.dinnerTime
        case "Dinner": return calendar.date(byAdding: .minute, value: -30, to: profile.sleepTime)!
        case "Sleep": return calendar.date(byAdding: .hour, value: 2, to: profile.sleepTime)!
        default: return Date.distantFuture
        }
    }
}
