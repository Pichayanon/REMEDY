import SwiftUI
import Charts

struct HistoryLogView: View {
    @ObservedObject var doseLogVM: DoseLogViewModel

    @State private var selectedRange: String = "Last 7 Days"
    @State private var searchText: String = ""

    let rangeOptions = ["Last 7 Days", "This Month"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SummaryChart(taken: totalTaken, missed: totalMissed)

                if let mostMissed = mostMissedMedication {
                    Text("Most missed: \(mostMissed.name) (\(mostMissed.count) times)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                Picker("Time Range", selection: $selectedRange) {
                    ForEach(rangeOptions, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                TextField("Search medication...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                ForEach(groupedDates(), id: \.self) { dateKey in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateKey)
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(groupedLogs()[dateKey] ?? []) { log in
                            HStack {
                                Circle()
                                    .fill(log.isTaken ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(log.medicationName)
                                        .fontWeight(.medium)
                                    Text("Meal: \(translatedMeal(log.meal))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Text(log.isTaken ? "Taken" : "Missed")
                                    .foregroundColor(log.isTaken ? .green : .red)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Medication History")
    }

    func filteredLogs() -> [DoseLog] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let logsInRange: [DoseLog] = {
            switch selectedRange {
            case "Last 7 Days":
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
                return doseLogVM.logs.filter { $0.date >= sevenDaysAgo }
            case "This Month":
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return doseLogVM.logs.filter { $0.date >= startOfMonth }
            default:
                return doseLogVM.logs
            }
        }()

        return logsInRange.filter {
            searchText.isEmpty || $0.medicationName.localizedCaseInsensitiveContains(searchText)
        }
    }

    func groupedLogs() -> [String: [DoseLog]] {
        Dictionary(grouping: filteredLogs()) { log in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: log.date)
        }
    }

    func groupedDates() -> [String] {
        groupedLogs().keys.sorted(by: >)
    }

    var totalTaken: Int {
        filteredLogs().filter { $0.isTaken }.count
    }

    var totalMissed: Int {
        filteredLogs().filter { !$0.isTaken }.count
    }

    var mostMissedMedication: (name: String, count: Int)? {
        let missed = filteredLogs().filter { !$0.isTaken }
        let grouped = Dictionary(grouping: missed, by: { $0.medicationName })
        let sorted = grouped.mapValues { $0.count }.sorted(by: { $0.value > $1.value })
        return sorted.first.map { ($0.key, $0.value) }
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


struct SummaryChart: View {
    let taken: Int
    let missed: Int

    var total: Int {
        max(taken + missed, 1)
    }

    var body: some View {
        VStack {
            Chart {
                SectorMark(angle: .value("Taken", taken))
                    .foregroundStyle(Color.green)
                    .annotation(position: .overlay) {
                        if taken > 0 {
                            Text("Taken \(percentage(taken))%")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }

                SectorMark(angle: .value("Missed", missed))
                    .foregroundStyle(Color.red)
                    .annotation(position: .overlay) {
                        if missed > 0 {
                            Text("Missed \(percentage(missed))%")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
            }
            .frame(height: 220)
            .padding(.horizontal)

        }
    }

    private func percentage(_ value: Int) -> Int {
        Int(round((Double(value) / Double(total)) * 100))
    }
}
