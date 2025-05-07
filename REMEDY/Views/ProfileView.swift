import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var breakfast = Date()
    @State private var lunch = Date()
    @State private var dinner = Date()
    @State private var sleep = Date()

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                TextField("Your Name", text: $name)
            }

            Section(header: Text("Meal Times")) {
                DatePicker("Breakfast", selection: $breakfast, displayedComponents: .hourAndMinute)
                DatePicker("Lunch", selection: $lunch, displayedComponents: .hourAndMinute)
                DatePicker("Dinner", selection: $dinner, displayedComponents: .hourAndMinute)
            }

            Section(header: Text("Sleep Time")) {
                DatePicker("Before Sleep", selection: $sleep, displayedComponents: .hourAndMinute)
            }

            Section {
                Button(action: {
                    let profile = UserProfile(
                        name: name,
                        breakfastTime: breakfast,
                        lunchTime: lunch,
                        dinnerTime: dinner,
                        sleepTime: sleep
                    )
                    authVM.saveUserProfile(profile)
                    dismiss()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    authVM.signOut()
                }) {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            if let p = authVM.userProfile {
                name = p.name
                breakfast = p.breakfastTime
                lunch = p.lunchTime
                dinner = p.dinnerTime
                sleep = p.sleepTime
            }
        }
    }
}
