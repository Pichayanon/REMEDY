import SwiftUI
import Charts

struct HistoryLogView: View {
    @ObservedObject var doseLogVM: DoseLogViewModel

    @State private var selectedRange: String = "7 วันล่าสุด"
    @State private var searchText: String = ""

    let rangeOptions = ["7 วันล่าสุด", "เดือนนี้"]

    var body: some View {
        VStack(spacing: 12) {
            SummaryChart(taken: totalTaken, missed: totalMissed)

            if let mostMissed = mostMissedMedication {
                Text("ลืมกินยาสูงสุด: \(mostMissed.name) (\(mostMissed.count) ครั้ง)")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            Picker("ช่วงเวลา", selection: $selectedRange) {
                ForEach(rangeOptions, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextField("ค้นหาชื่อยา", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            List {
                ForEach(groupedDates(), id: \.self) { dateKey in
                    Section(header: Text(dateKey).font(.headline)) {
                        ForEach(groupedLogs()[dateKey] ?? []) { log in
                            HStack {
                                Circle()
                                    .fill(log.isTaken ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading) {
                                    Text(log.medicationName)
                                        .fontWeight(.medium)
                                    Text("มื้อ: \(translatedMeal(log.meal))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(log.isTaken ? "ทานแล้ว" : "ไม่ได้ทาน")
                                    .foregroundColor(log.isTaken ? .green : .red)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("ประวัติการกินยา")
    }

    func filteredLogs() -> [DoseLog] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let logsInRange: [DoseLog] = {
            switch selectedRange {
            case "7 วันล่าสุด":
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
                return doseLogVM.logs.filter { $0.date >= sevenDaysAgo }
            case "เดือนนี้":
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
        if let first = sorted.first {
            return (first.key, first.value)
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

