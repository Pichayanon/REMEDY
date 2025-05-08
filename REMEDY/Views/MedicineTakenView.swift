import SwiftUI

struct MedicineTakenView: View {
    @ObservedObject var viewModel: MedicationViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var doseLogVM = DoseLogViewModel()

    @State private var filter: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "ทั้งหมด"
        case taken = "ทานแล้ว"
        case notTaken = "ยังไม่ทาน"
    }

    var currentMeal: String? {
        getCurrentMeal(from: authVM.userProfile)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("ทานยามื้อ: \(translatedMeal(currentMeal ?? "-"))")
                    .font(.title2.bold())
                    .padding(.top)

                if currentMeal == nil {
                    Text("ยังไม่ถึงเวลาทานยา")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Picker("Filter", selection: $filter) {
                        ForEach(FilterType.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    List {
                        ForEach(filteredMeds(), id: \.id) { med in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(med.name)
                                        .fontWeight(.semibold)
                                    Text("จำนวนที่เหลือ: \(med.totalPills)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                if hasAlreadyTaken(medication: med, meal: currentMeal!) {
                                    Text("Done")
                                        .foregroundColor(.green)
                                } else {
                                    Button("ทานแล้ว") {
                                        doseLogVM.addLog(medication: med, meal: currentMeal!)
                                        viewModel.markAsTaken(medication: med)
                                    }
                                    .padding(6)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("บันทึกการทานยา")
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
        case "Breakfast": return "เช้า"
        case "Lunch": return "กลางวัน"
        case "Dinner": return "เย็น"
        case "Sleep": return "ก่อนนอน"
        default: return meal
        }
    }
}
