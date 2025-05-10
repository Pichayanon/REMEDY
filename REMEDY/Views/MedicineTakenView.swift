import SwiftUI

struct MedicineTakenView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var doseLogVM = DoseLogViewModel()

    @State private var refreshTrigger = false
    private let snoozeRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
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

                                    ForEach(beforeMealMeds + afterMealMeds, id: \.id) { med in
                                        MedicationCard(med: med, meal: meal)
                                    }
                                }
                            }
                        }
                        .id(refreshTrigger)
                    }
                }
            }
        }
        .onAppear {
            SnoozeManager.shared.clearExpired()
        }
        .onReceive(snoozeRefreshTimer) { _ in
            SnoozeManager.shared.clearExpired()
            refreshTrigger.toggle()
        }
    }

    @ViewBuilder
    func MedicationCard(med: Medication, meal: String) -> some View {
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
                    HStack(spacing: 8) {
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

                        let id = "\(med.id.uuidString)_\(mealIndex(meal))"
                        let count = SnoozeManager.shared.snoozeCount(for: id)
                        let isSnoozed = SnoozeManager.shared.isSnoozed(id: id)

                        if let scheduled = scheduledTime(for: med, meal: meal),
                           Date() >= scheduled,
                           !isSnoozed,
                           count < 2 {
                            Button("Remind in 10 min") {
                                NotificationManager.shared.rescheduleIn(minutes: 1, for: id)
                                SnoozeManager.shared.incrementSnooze(id: id, durationMinutes: 1)
                                refreshTrigger.toggle()
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                        }
                    }
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

    // MARK: - Helpers
    func translatedMeal(_ meal: String) -> String {
        switch meal {
        case "Breakfast": return "Morning"
        case "Lunch": return "Afternoon"
        case "Dinner": return "Evening"
        case "Sleep": return "Before Bed"
        default: return meal
        }
    }

    func mealIndex(_ meal: String) -> Int {
        switch meal {
        case "Breakfast": return 0
        case "Lunch": return 1
        case "Dinner": return 2
        case "Sleep": return 3
        default: return 0
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

    func scheduledTime(for medication: Medication, meal: String) -> Date? {
        guard let profile = authVM.userProfile else { return nil }

        let baseTime: Date? = switch meal {
        case "Breakfast": profile.breakfastTime
        case "Lunch": profile.lunchTime
        case "Dinner": profile.dinnerTime
        case "Sleep": profile.sleepTime
        default: nil
        }

        guard let base = baseTime else { return nil }

        let offset: Int
        if meal == "Sleep" {
            offset = -30 
        } else {
            offset = medication.mealTiming == "Before Meal" ? -30 : 30
        }

        let scheduled = Calendar.current.date(byAdding: .minute, value: offset, to: base)

        if let scheduled = scheduled {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: scheduled)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                 minute: components.minute ?? 0,
                                 second: 0,
                                 of: Date())
        }

        return nil
    }

}
