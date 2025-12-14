import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var authViewModel: AppleAuthViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date() // Default to 18 years ago
    @State private var errorMessage: String?
    @State private var isLoading = false

    var age: Int {
        let calendar = Calendar.current
        let birthComponents = calendar.dateComponents([.year], from: dateOfBirth)
        let todayComponents = calendar.dateComponents([.year], from: Date())
        return (todayComponents.year ?? 0) - (birthComponents.year ?? 0)
    }

    var isAdult: Bool {
        age >= 18
    }

    var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }

                Section(header: Text("Date of Birth")) {
                    DatePicker(
                        "Select date",
                        selection: $dateOfBirth,
                        displayedComponents: [.date]
                    )
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Continue")
                        }
                    }
                    .disabled(!canSubmit || isLoading)
                }
            }
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func saveProfile() {
        guard isAdult else {
            errorMessage = "You must be 18 or older."
            return
        }

        isLoading = true
        errorMessage = nil

        if let userID = authViewModel.userID {
            let profile = UserProfile(
                appleUserID: userID,
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces),
                dateOfBirth: dateOfBirth
            )
            modelContext.insert(profile)
            authViewModel.completeProfileSetup(userProfile: profile)
        } else {
            errorMessage = "User ID not available."
            isLoading = false
        }
    }
}

#Preview {
    ProfileSetupView(authViewModel: AppleAuthViewModel())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
