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
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Medication Taken")
                        .font(.largeTitle.bold())
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.horizontal)

                    if let meal = currentMeal {
                        Text("\(translatedMeal(meal)) Meal")
                            .font(.title3.bold())
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        Picker("Filter", selection: $filter) {
                            ForEach(FilterType.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                }

                if currentMeal == nil {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No scheduled medication for this time.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    if filteredMeds().isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "pills.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No medicines for this meal")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filteredMeds(), id: \.id) { med in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Label(med.name, systemImage: "pills.fill")
                                                .font(.headline)
                                                .foregroundColor(.purple)
                                            Spacer()
                                            if hasAlreadyTaken(medication: med, meal: currentMeal!) {
                                                Text("Taken")
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color.green.opacity(0.2))
                                                    .foregroundColor(.green)
                                                    .cornerRadius(12)
                                            } else {
                                                Button(action: {
                                                    doseLogVM.addLog(medication: med, meal: currentMeal!)
                                                    viewModel.markAsTaken(medication: med)
                                                }) {
                                                    Text("Mark as Taken")
                                                        .font(.caption)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 6)
                                                        .background(Color.blue.opacity(0.15))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(12)
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
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            .padding(.top, 8)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    func filteredMeds() -> [Medication] {
        guard let meal = currentMeal else { return [] }
        let all = viewModel.medications.filter { $0.mealTimes.contains(meal) }

        switch filter {
        case .all: return all
        case .taken: return all.filter { hasAlreadyTaken(medication: $0, meal: meal) }
        case .notTaken: return all.filter { !hasAlreadyTaken(medication: $0, meal: meal) }
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
