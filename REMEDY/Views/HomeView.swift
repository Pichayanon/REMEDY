import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var medicationVM = MedicationViewModel()

    @State private var showAddMedicine = false
    @State private var editingMedication: Medication? = nil
    @State private var showProfile = false
    @State private var showTaken = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Hello \(authVM.userProfile?.name ?? "there") 👋")
                            .font(.title.bold())
                        Spacer()
                        Button(action: { showProfile = true }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.purple)
                        }
                    }

                    HStack {
                        Text("Your Medicines")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Taken") {
                            showTaken = true
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                    }

                    ForEach(medicationVM.medications) { med in
                        MedicationCardView(
                            medication: med,
                            onEdit: {
                                editingMedication = med
                                showAddMedicine = true
                            },
                            onDelete: {
                                medicationVM.deleteMedication(med)
                            }
                        )
                    }

                    Button(action: {
                        editingMedication = nil
                        showAddMedicine = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Medicine")
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }

            .sheet(isPresented: $showAddMedicine) {
                MedicationAddView(medicationToEdit: editingMedication)
                    .environmentObject(medicationVM)
            }

            .sheet(isPresented: $showProfile) {
                NavigationView {
                    ProfileView()
                        .environmentObject(authVM)
                }
            }

            .sheet(isPresented: $showTaken) {
                MedicineTakenView(viewModel: medicationVM)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
