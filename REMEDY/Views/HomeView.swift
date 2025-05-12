import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var medicationVM = MedicationViewModel()
    @StateObject private var doseLogVM = DoseLogViewModel()

    @State private var showAddMedicine = false
    @State private var editingMedication: Medication? = nil
    @State private var showProfile = false
    @State private var showTaken = false
    @State private var showHistory = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.purple.opacity(0.1), Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Hello \(authVM.userProfile?.name ?? "there") 👋")
                                .font(.title.bold())
                                .foregroundColor(.purple)
                            Spacer()
                            Button(action: { showProfile = true }) {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.purple)
                            }
                        }

                        HStack(spacing: 12) {
                            Text("Your Medicines")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Taken") {
                                showTaken = true
                            }
                            .buttonStyle(SoftTagButtonStyle(color: .green))

                            Button("History") {
                                showHistory = true
                            }
                            .buttonStyle(SoftTagButtonStyle(color: .blue))
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
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                                Text("Add New Medicine")
                                    .fontWeight(.medium)
                                    .font(.title3)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.05)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.purple)
                            .cornerRadius(20)
                            .shadow(color: Color.purple.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)

                    }
                    .padding()
                }
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

            .sheet(isPresented: $showHistory) {
                NavigationView {
                    HistoryLogView(doseLogVM: doseLogVM)
                }
            }
            
            .onAppear {
                medicationVM.loadMedications { meds in
                    doseLogVM.autoLogMissedDoses(for: meds)
                }
            }
        }
    }
}

struct SoftTagButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

