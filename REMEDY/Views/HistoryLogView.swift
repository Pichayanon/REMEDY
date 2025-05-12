import SwiftUI

struct HistoryLogView: View {
    @ObservedObject var doseLogVM: DoseLogViewModel

    @State private var selectedRange: String = "Last 7 Days"
    @State private var searchText: String = ""
    @State private var takenFilter: String = "All"

    let rangeOptions = ["Last 7 Days", "This Month"]
    let takenOptions = ["All", "Taken", "Missed"]

    var filteredLogs: [DoseLog] {
        var logs = doseLogVM.logs.filter { log in
            (searchText.isEmpty || log.medicationName.lowercased().contains(searchText.lowercased())) &&
            isInSelectedRange(log.date)
        }

        if takenFilter == "Taken" {
            logs = logs.filter { $0.isTaken }
        } else if takenFilter == "Missed" {
            logs = logs.filter { !$0.isTaken }
        }

        return logs.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Text("History Log")
                            .font(.largeTitle.bold())
                            .foregroundColor(.purple)

                        Spacer()

                        NavigationLink(destination: DashboardView(doseLogVM: doseLogVM)) {
                            Text("Dashboard")
                        }
                        .buttonStyle(SoftTagButtonStyle(color: .blue))
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)


                    Picker("Status", selection: $takenFilter) {
                        ForEach(takenOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    TextField("Search medicine", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack {
                        Text("Total: \(filteredLogs.count)")
                        Spacer()
                        Text("Taken: \(filteredLogs.filter { $0.isTaken }.count)")
                        Text("Missed: \(filteredLogs.filter { !$0.isTaken }.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }

                if filteredLogs.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No history records found")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredLogs) { log in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Label(log.medicationName, systemImage: "pills.fill")
                                            .font(.headline)
                                            .foregroundColor(.purple)
                                        Spacer()
                                        Text(formattedDate(log.date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    HStack {
                                        Text("Meal: \(log.meal)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(log.isTaken ? "Taken" : "Missed")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(log.isTaken ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                            .foregroundColor(log.isTaken ? .green : .red)
                                            .cornerRadius(8)
                                    }
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

                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    func isInSelectedRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        switch selectedRange {
        case "Last 7 Days":
            guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return true }
            return date >= sevenDaysAgo
        case "This Month":
            return calendar.isDate(date, equalTo: today, toGranularity: .month)
        default:
            return true
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
