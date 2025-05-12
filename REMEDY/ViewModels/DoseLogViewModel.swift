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

    func markTakenDose(medication: Medication, meal: String, date: Date = Date()) {
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
    
    func autoLogMissedDoses(for medications: [Medication]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfYesterday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!

        self.db.collection("users").document(uid).collection("doseLogs")
            .whereField("date", isGreaterThanOrEqualTo: startOfYesterday)
            .whereField("date", isLessThanOrEqualTo: endOfYesterday)
            .getDocuments { snapshot, error in
                guard error == nil, let documents = snapshot?.documents else {
                    print("Error fetching dose logs:", error?.localizedDescription ?? "")
                    return
                }
                let logs = documents.compactMap { try? $0.data(as: DoseLog.self) }

                for med in medications {
                    var allMeals = med.mealTimes
                    if med.isBeforeSleep {
                        allMeals.append("Sleep")
                    }

                    for meal in allMeals {
                        let alreadyLogged = logs.contains {
                            $0.medicationID == med.id && $0.meal == meal
                        }

                        if !alreadyLogged {
                            let missedLog = DoseLog(
                                medicationID: med.id,
                                medicationName: med.name,
                                date: endOfYesterday,
                                meal: meal,
                                isTaken: false
                            )

                            do {
                                try self.db.collection("users").document(uid).collection("doseLogs")
                                    .document(missedLog.id.uuidString)
                                    .setData(from: missedLog)
                                print("Missed dose logged: \(med.name) - \(meal)")
                            } catch {
                                print("Failed to log missed dose:", error.localizedDescription)
                            }
                        }
                    }
                }
            }
    }
}
