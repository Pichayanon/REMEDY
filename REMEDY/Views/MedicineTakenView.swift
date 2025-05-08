import SwiftUI

struct MedicineTakenView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var doseLogVM = DoseLogViewModel()
    @State private var filter: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "All"
        case taken = "Taken"
        case notTaken = "Not Taken"
    }

    var currentMeal: String? {
        getCurrentMeal(from: authVM.userProfile)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("\(translatedMeal(currentMeal ?? "-")) Meal")
                    .font(.title2.bold())
                    .padding(.top)

                if currentMeal == nil {
                    Text("It's not time for any medication yet.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Picker("Filter", selection: $filter) {
                        ForEach(FilterType.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredMeds(), id: \.id) { med in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(med.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Remaining pills: \(med.totalPills)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    if hasAlreadyTaken(medication: med, meal: currentMeal!) {
                                        Text("Taken")
                                            .font(.caption)
                                            .padding(6)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(.green)
                                            .cornerRadius(8)
                                    } else {
                                        Button(action: {
                                            doseLogVM.addLog(medication: med, meal: currentMeal!)
                                            viewModel.markAsTaken(medication: med)
                                        }) {
                                            Text("Mark as Taken")
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.15))
                                                .foregroundColor(.blue)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Medication Taken")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    func filteredMeds() -> [Medication] {
        guard let meal = currentMeal else { return [] }

        let all = viewModel.medications.filter { $0.mealTimes.contains(meal) }

        switch filter {
        case .all:
            return all
        case .taken:
            return all.filter { hasAlreadyTaken(medication: $0, meal: meal) }
        case .notTaken:
            return all.filter { !hasAlreadyTaken(medication: $0, meal: meal) }
        }
    }

    func hasAlreadyTaken(medication: Medication, meal: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return doseLogVM.logs.contains {
            $0.medicationID == medication.id &&
            $0.meal == meal &&
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

    func getCurrentMeal(from profile: UserProfile?) -> String? {
        guard let profile = profile else { return nil }
        let now = Date()
        let calendar = Calendar.current

        func isBetween(_ start: Date, _ end: Date) -> Bool {
            return now >= start && now < end
        }

        let breakfast = profile.breakfastTime
        let lunch = profile.lunchTime
        let dinner = profile.dinnerTime
        let sleep = profile.sleepTime

        let lunchEnd = calendar.date(byAdding: .hour, value: 6, to: lunch)!
        let dinnerEnd = calendar.date(byAdding: .hour, value: 6, to: dinner)!
        let sleepEnd = calendar.date(byAdding: .hour, value: 6, to: sleep)!

        if isBetween(breakfast, lunch) {
            return "Breakfast"
        } else if isBetween(lunch, dinner) {
            return "Lunch"
        } else if isBetween(dinner, sleep) {
            return "Dinner"
        } else if isBetween(sleep, sleepEnd) {
            return "Sleep"
        }

        return nil
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
}
