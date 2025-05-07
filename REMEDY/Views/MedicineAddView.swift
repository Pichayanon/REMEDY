import SwiftUI

struct MedicationAddView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MedicationViewModel

    let medicationToEdit: Medication?

    @State private var name = ""
    @State private var mealTiming = "After Meal"
    @State private var mealTimes = Set<String>()
    @State private var isBeforeSleep = false
    @State private var totalPills = ""
    @State private var pillsPerDose = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Info")) {
                    TextField("ชื่อยา", text: $name)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Meal Timing")) {
                    Picker("Meal Timing", selection: $mealTiming) {
                        Text("Before Meal").tag("Before Meal")
                        Text("After Meal").tag("After Meal")
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Breakfast", isOn: mealBinding(for: "Breakfast"))
                        Toggle("Lunch", isOn: mealBinding(for: "Lunch"))
                        Toggle("Dinner", isOn: mealBinding(for: "Dinner"))
                    }
                    .padding(.leading)
                }

                Section(header: Text("Night Dose")) {
                    Toggle("Before Sleep", isOn: $isBeforeSleep)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }

                Section(header: Text("Dosage Info")) {
                    TextField("จำนวนยาทั้งหมด", text: $totalPills)
                        .keyboardType(.numberPad)
                    TextField("จำนวนยาต่อครั้ง", text: $pillsPerDose)
                        .keyboardType(.numberPad)
                }

                Button(action: saveMedication) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle(medicationToEdit == nil ? "Add Medicine" : "Edit Medicine")
            .onAppear {
                if let med = medicationToEdit {
                    name = med.name
                    mealTiming = med.mealTiming
                    mealTimes = Set(med.mealTimes)
                    isBeforeSleep = med.isBeforeSleep
                    totalPills = String(med.totalPills)
                    pillsPerDose = String(med.pillsPerDose)
                }
            }
        }
    }

    private func mealBinding(for meal: String) -> Binding<Bool> {
        Binding(
            get: { mealTimes.contains(meal) },
            set: { newValue in
                if newValue {
                    mealTimes.insert(meal)
                } else {
                    mealTimes.remove(meal)
                }
            }
        )
    }

    private func saveMedication() {
        let total = Int(totalPills) ?? 0
        let perDose = Int(pillsPerDose) ?? 1

        let newMed = Medication(
            id: medicationToEdit?.id ?? UUID(),
            name: name,
            mealTiming: mealTiming,
            mealTimes: Array(mealTimes),
            isBeforeSleep: isBeforeSleep,
            totalPills: total,
            pillsPerDose: perDose
        )

        if let existing = medicationToEdit {
            viewModel.deleteMedication(existing)
        }

        viewModel.addMedication(newMed)

        dismiss()
    }
}
