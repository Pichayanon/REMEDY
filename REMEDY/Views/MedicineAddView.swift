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
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text(medicationToEdit == nil ? "Add Medicine" : "Edit Medicine")
                        .font(.largeTitle.bold())
                        .foregroundColor(.purple)
                        .padding(.top, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Medicine Name", systemImage: "pills.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        TextField("Enter name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Meal Timing", systemImage: "fork.knife")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        Picker("Meal Timing", selection: $mealTiming) {
                            Text("Before Meal").tag("Before Meal")
                            Text("After Meal").tag("After Meal")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Meal Times", systemImage: "clock")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        Toggle("Breakfast", isOn: mealBinding(for: "Breakfast"))
                        Toggle("Lunch", isOn: mealBinding(for: "Lunch"))
                        Toggle("Dinner", isOn: mealBinding(for: "Dinner"))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Night Dose", systemImage: "moon.zzz.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        Toggle("Before Sleep", isOn: $isBeforeSleep)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Dosage", systemImage: "capsule")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        TextField("Total Pills", text: $totalPills)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Pills per Dose", text: $pillsPerDose)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    Button(action: saveMedication) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
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
        .alert("Incomplete Information", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
            alertMessage = "Please enter medicine name."
            showAlert = true
            return
        }

        guard !mealTimes.isEmpty || isBeforeSleep else {
            alertMessage = "Please select at least one meal or before sleep."
            showAlert = true
            return
        }

        guard let total = Int(cleanTotal), total > 0 else {
            alertMessage = "Please enter a valid total pill amount."
            showAlert = true
            return
        }

        guard let perDose = Int(cleanPerDose), perDose > 0 else {
            alertMessage = "Please enter a valid pills-per-dose value."
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
