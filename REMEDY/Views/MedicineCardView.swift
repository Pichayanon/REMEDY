import SwiftUI

struct MedicationCardView: View {
    let medication: Medication
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(medication.name, systemImage: "pills.fill")
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

            Text("Remaining pills: \(medication.totalPills)")
                .font(.caption)
                .foregroundColor(.gray)

            let orderedMeals = ["Breakfast", "Lunch", "Dinner"]

            if !medication.mealTimes.isEmpty || medication.isBeforeSleep {
                HStack(spacing: 8) {
                    ForEach(orderedMeals, id: \.self) { meal in
                        if medication.mealTimes.contains(meal) {
                            Label {
                                Text(meal)
                            } icon: {
                                Image(systemName: iconName(for: meal))
                            }
                            .font(.caption)
                            .foregroundColor(color(for: meal))
                        }
                    }

                    if medication.isBeforeSleep {
                        Label("Before Sleep", systemImage: "moon.zzz.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

func iconName(for meal: String) -> String {
    switch meal {
    case "Breakfast": return "cup.and.saucer.fill"
    case "Lunch": return "fork.knife.circle.fill"
    case "Dinner": return "takeoutbag.and.cup.and.straw.fill"
    default: return "checkmark.circle.fill"
    }
}

func color(for meal: String) -> Color {
    switch meal {
    case "Breakfast": return .orange
    case "Lunch": return .green
    case "Dinner": return .blue
    default: return .gray
    }
}
