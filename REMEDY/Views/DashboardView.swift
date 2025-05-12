import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var doseLogVM = DoseLogViewModel()
    @State private var selectedRange = "Last 7 Days"

    let rangeOptions = ["Last 7 Days", "This Month"]

    var filteredLogs: [DoseLog] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedRange {
        case "Last 7 Days":
            let startDate = calendar.date(byAdding: .day, value: -6, to: now)!
            return doseLogVM.logs.filter { $0.date >= startDate }
        case "This Month":
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return doseLogVM.logs.filter { $0.date >= startOfMonth }
        default:
            return doseLogVM.logs
        }
    }

    var totalTaken: Int {
        filteredLogs.filter { $0.isTaken }.count
    }

    var totalMissed: Int {
        filteredLogs.filter { !$0.isTaken }.count
    }

    var percentTaken: Int {
        let total = totalTaken + totalMissed
        guard total > 0 else { return 0 }
        return Int((Double(totalTaken) / Double(total)) * 100)
    }

    var percentMissed: Int {
        100 - percentTaken
    }

    var mostMissedMedication: (name: String, count: Int)? {
        let missed = filteredLogs.filter { !$0.isTaken }
        let grouped = Dictionary(grouping: missed, by: { $0.medicationName })
        let sorted = grouped.mapValues { $0.count }.sorted { $0.value > $1.value }
        return sorted.first.map { ($0.key, $0.value) }
    }

    var mostMissedMeal: (meal: String, count: Int)? {
        let missed = filteredLogs.filter { !$0.isTaken }
        let grouped = Dictionary(grouping: missed, by: { $0.meal })
        let sorted = grouped.mapValues { $0.count }.sorted { $0.value > $1.value }
        return sorted.first.map { ($0.key, $0.value) }
    }

    var body: some View {
        ZStack {
            Color.purple.opacity(0.05).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Medication Dashboard")
                        .font(.largeTitle.bold())
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.horizontal)

                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(rangeOptions, id: \.self) { range in
                            Text(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Taken vs Missed", systemImage: "chart.pie.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            Chart {
                                if totalTaken > 0 {
                                    SectorMark(
                                        angle: .value("Taken", totalTaken),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(Color.green)
                                }

                                if totalMissed > 0 {
                                    SectorMark(
                                        angle: .value("Missed", totalMissed),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(Color.red)
                                }
                            }
                            .frame(height: 200)

                            VStack(spacing: 4) {
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(totalTaken + totalMissed)")
                                    .font(.title2.bold())
                            }
                        }

                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 12, height: 12)
                                Text("Taken: \(percentTaken)%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                Text("Missed: \(percentMissed)%")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    if let mostMissed = mostMissedMedication {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Most Missed Medication", systemImage: "pills.fill")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(mostMissed.name) (\(mostMissed.count) times)")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }

                    if let mostMissed = mostMissedMeal {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Most Missed Time", systemImage: "clock.fill")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(mostMissed.meal) (\(mostMissed.count) times)")
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.bottom)
            }
        }
    }
}
