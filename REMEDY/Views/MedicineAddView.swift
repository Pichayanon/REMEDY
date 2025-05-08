import SwiftUI

struct MedicationAddView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MedicationViewModel
    @EnvironmentObject var authVM: AuthViewModel

    let medicationToEdit: Medication?

    @State private var name = ""
    @State private var mealTiming = "After Meal"
    @State private var mealTimes = Set<String>()
    @State private var isBeforeSleep = false
    @State private var totalPills = ""
    @State private var pillsPerDose = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

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
            .alert("กรอกข้อมูลไม่ครบ", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
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
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTotal = totalPills.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPerDose = pillsPerDose.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            alertMessage = "กรุณากรอกชื่อยา"
            showAlert = true
            return
        }
        
        guard !mealTimes.isEmpty || isBeforeSleep else {
            alertMessage = "กรุณาเลือกอย่างน้อยหนึ่งมื้อ หรือก่อนนอน"
            showAlert = true
            return
        }

        guard let total = Int(cleanTotal), total > 0 else {
            alertMessage = "กรุณากรอกจำนวนยาทั้งหมดให้ถูกต้อง"
            showAlert = true
            return
        }

        guard let perDose = Int(cleanPerDose), perDose > 0 else {
            alertMessage = "กรุณากรอกจำนวนยาต่อครั้งให้ถูกต้อง"
            showAlert = true
            return
        }

        let newMed = Medication(
            id: medicationToEdit?.id ?? UUID(),
            name: cleanName,
            mealTiming: mealTiming,
            mealTimes: Array(mealTimes),
            isBeforeSleep: isBeforeSleep,
            totalPills: total,
            pillsPerDose: perDose
        )

        if let existing = medicationToEdit {
            viewModel.deleteMedication(existing)
        }

        if let profile = authVM.userProfile {
            viewModel.addMedication(newMed, userProfile: profile)
        }
        dismiss()
    }
}
