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

    func addMedication(_ medication: Medication) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            _ = try db.collection("users").document(uid).collection("medications")
                .document(medication.id.uuidString)
                .setData(from: medication)
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
}
