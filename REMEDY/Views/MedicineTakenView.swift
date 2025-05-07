import SwiftUI

struct MedicineTakenView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.medications) { med in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(med.name)
                            .font(.headline)
                            .foregroundColor(.purple)

                        Text("\(med.pillsPerDose) pills per dose")
                            .font(.subheadline)

                        if !med.mealTimes.isEmpty {
                            Text("Meals: \(med.mealTimes.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if med.isBeforeSleep {
                            Text("Before Sleep")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Button("Mark as Taken") {
                            viewModel.markAsTaken(medication: med)
                        }
                        .padding(6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Mark as Taken")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
