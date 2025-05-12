import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var breakfast = Date()
    @State private var lunch = Date()
    @State private var dinner = Date()
    @State private var sleep = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""


    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.purple.opacity(0.1), Color.white],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Profile Settings")
                        .font(.largeTitle.bold())
                        .foregroundColor(.purple)
                        .padding(.top, 32)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Your Name", systemImage: "person")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        TextField("Enter your name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Meal Times", systemImage: "fork.knife")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        mealRow(title: "Breakfast", time: $breakfast)
                        mealRow(title: "Lunch", time: $lunch)
                        mealRow(title: "Dinner", time: $dinner)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sleep Time", systemImage: "bed.double.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)

                        mealRow(title: "Before Sleep", time: $sleep)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    Button(action: saveProfile) {
                        Text("Save")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal)

                    Button(action: { authVM.signOut() }) {
                        Text("Sign Out")
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
            if let p = authVM.userProfile {
                name = p.name
                breakfast = p.breakfastTime
                lunch = p.lunchTime
                dinner = p.dinnerTime
                sleep = p.sleepTime
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Time Setup"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func mealRow(title: String, time: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .font(.body)
    }

    func saveProfile() {
        let calendar = Calendar.current
        func timeOnly(_ date: Date) -> Date {
            let comps = calendar.dateComponents([.hour, .minute], from: date)
            return calendar.date(from: comps) ?? date
        }

        let breakfastTime = timeOnly(breakfast)
        let lunchTime = timeOnly(lunch)
        let dinnerTime = timeOnly(dinner)
        let sleepTime = timeOnly(sleep)

        if breakfastTime >= lunchTime {
            alertMessage = "Breakfast time must be before Lunch."
            showAlert = true
            return
        }

        if lunchTime >= dinnerTime {
            alertMessage = "Lunch time must be before Dinner."
            showAlert = true
            return
        }

        if dinnerTime >= sleepTime {
            alertMessage = "Dinner time must be before Sleep."
            showAlert = true
            return
        }

        let sleepHour = calendar.component(.hour, from: sleep)
        if sleepHour >= 24 || sleepHour < 0 {
            alertMessage = "Sleep time must be before midnight."
            showAlert = true
            return
        }

        let profile = UserProfile(
            name: name,
            breakfastTime: breakfast,
            lunchTime: lunch,
            dinnerTime: dinner,
            sleepTime: sleep
        )
        authVM.saveUserProfile(profile)
        dismiss()
    }
}
