import SwiftUI

struct MedicineTakenView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var doseLogVM = DoseLogViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Today's Medication")
                        .font(.largeTitle.bold())
                        .foregroundColor(.purple)
                        .padding(.top, 16)
                        .padding(.horizontal)

                    if let _ = authVM.userProfile {
                        ForEach(["Breakfast", "Lunch", "Dinner", "Sleep"], id: \.self) { meal in
                            let medsForMeal = viewModel.medications.filter {
                                $0.mealTimes.contains(meal) || (meal == "Sleep" && $0.isBeforeSleep)
                            }

                            let beforeMealMeds = medsForMeal.filter { $0.mealTiming == "Before Meal" }
                            let afterMealMeds = medsForMeal.filter { $0.mealTiming == "After Meal" }

                            if !medsForMeal.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(translatedMeal(meal))
                                        .font(.title3.bold())
                                        .foregroundColor(.purple)
                                        .padding(.horizontal)

                                    if !beforeMealMeds.isEmpty {
                                        if meal != "Sleep" {
                                            Text("Before Meal")
                                                .font(.headline)
                                                .foregroundColor(.purple.opacity(0.8))
                                                .padding(.horizontal)
                                        }

                                        ForEach(beforeMealMeds, id: \.id) { med in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Label(med.name, systemImage: "pills.fill")
                                                        .font(.headline)
                                                        .foregroundColor(.purple)
                                                    Spacer()

                                                    if let log = getTodayLog(for: med, meal: meal) {
                                                        Text(log.isTaken ? "Taken" : "Missed")
                                                            .font(.caption)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 6)
                                                            .background(log.isTaken ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                                            .foregroundColor(log.isTaken ? .green : .red)
                                                            .cornerRadius(12)
                                                    } else {
                                                        Button("Mark as Taken") {
                                                            doseLogVM.markTakenDose(medication: med, meal: meal)
                                                            viewModel.reduceMedication(medication: med)
                                                        }
                                                        .font(.caption)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.15))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(12)
                                                    }
                                                }

                                                Text("Remaining pills: \(med.totalPills)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(16)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            .padding(.horizontal)
                                        }
                                    }

                                    if !afterMealMeds.isEmpty {
                                        if meal != "Sleep" {
                                            Text("After Meal")
                                                .font(.headline)
                                                .foregroundColor(.purple.opacity(0.8))
                                                .padding(.horizontal)
                                        }

                                        ForEach(afterMealMeds, id: \.id) { med in
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Label(med.name, systemImage: "pills.fill")
                                                        .font(.headline)
                                                        .foregroundColor(.purple)
                                                    Spacer()

                                                    if let log = getTodayLog(for: med, meal: meal) {
                                                        Text(log.isTaken ? "Taken" : "Missed")
                                                            .font(.caption)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 6)
                                                            .background(log.isTaken ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                                            .foregroundColor(log.isTaken ? .green : .red)
                                                            .cornerRadius(12)
                                                    } else {
                                                        Button("Mark as Taken") {
                                                            doseLogVM.markTakenDose(medication: med, meal: meal)
                                                            viewModel.reduceMedication(medication: med)
                                                        }
                                                        .font(.caption)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.15))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(12)
                                                    }
                                                }

                                                Text("Remaining pills: \(med.totalPills)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(16)
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func translatedMeal(_ meal: String) -> String {
        switch meal {
        case "Breakfast": return "Morning"
        case "Lunch": return "Afternoon"
        case "Dinner": return "Evening"
        case "Sleep": return "Before Bed"
        default: return meal
        }
    }

    func getTodayLog(for medication: Medication, meal: String) -> DoseLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return doseLogVM.logs.first {
            $0.medicationID == medication.id &&
            $0.meal == meal &&
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }
}
