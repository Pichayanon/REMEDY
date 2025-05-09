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

}
