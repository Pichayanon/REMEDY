import SwiftUI

struct MedicationCardView: View {
    let medication: Medication
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medication.name)
                    .font(.headline)
                    .foregroundColor(.purple)
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.gray)
                }
            }

            Text(medication.mealTiming)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !medication.mealTimes.isEmpty {
                HStack {
                    ForEach(medication.mealTimes, id: \.self) { meal in
                        Label(meal, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            if medication.isBeforeSleep {
                HStack {
                    Label("Before Sleep", systemImage: "moon.zzz.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
