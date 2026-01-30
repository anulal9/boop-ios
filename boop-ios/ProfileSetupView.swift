import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var errorMessage: String?
    @State private var isLoading = false

    // Photo picker state
    @State private var imageSelection: PhotosPickerItem?
    @State private var avatarImage: AvatarImage?

    // Mode control
    let isSetupMode: Bool
    let onProfileUpdated: (() -> Void)?

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
        !firstName.isEmptyAfterSanitizing
            && !lastName.isEmptyAfterSanitizing
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading profile...")
                            .subtitleStyle()
                    }
                } else {
                    Form {
                        Section(header: Text("Profile Photo")) {
                            HStack {
                                Group {
                                    if let avatarImage {
                                        avatarImage.image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())

                                Spacer()

                                PhotosPicker(selection: $imageSelection, matching: .images) {
                                    Label("Select Photo", systemImage: "photo")
                                }
                            }
                        }

                        Section(header: Text("Profile Information")) {
                            TextField("First Name", text: $firstName)
                            TextField("Last Name", text: $lastName)
                        }

                        if isSetupMode {
                            Section(header: Text("Date of Birth")) {
                                DatePicker(
                                    "Select date",
                                    selection: $dateOfBirth,
                                    displayedComponents: [.date]
                                )
                            }
                        } else {
                            Section(header: Text("Date of Birth")) {
                                Text(formattedDate(dateOfBirth) ?? "Unknown")
                            }
                        }

                        if let errorMessage = errorMessage {
                            Section {
                                Text(errorMessage)
                                    .errorTextStyle()
                            }
                        }

                        Section {
                            Button(action: saveProfile) {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text(isSetupMode ? "Continue" : "Save")
                                }
                            }
                            .disabled(!canSubmit || isLoading)
                        }
                    }
                }
            }
            .navigationTitle(isSetupMode ? "Your Profile" : "You")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: imageSelection) { _, newValue in
                guard let newValue else { return }
                loadTransferable(from: newValue)
            }
            .task {
                if !isSetupMode {
                    await loadProfile()
                }
            }
        }
        .pageBackground()
    }

    private func formattedDate(_ date: Date) -> String? {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }
        return "\(month)/\(day)/\(year)"
    }

    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        Task {
            do {
                avatarImage = try await imageSelection.loadTransferable(type: AvatarImage.self)
            } catch {
                print("⚠️ Failed to load image: \(error.localizedDescription)")
            }
        }
    }

    private func saveProfile() {
        if isSetupMode {
            saveProfileSetup()
        } else {
            saveProfileEdit()
        }
    }

    private func saveProfileSetup() {
        Task {
            isLoading = true
            errorMessage = nil

            // Create local profile
            let profile = UserProfile(
                firstName: firstName.sanitize(),
                lastName: lastName.sanitize(),
                dateOfBirth: dateOfBirth,
                avatarData: avatarImage?.data
            )

            // Save locally
            modelContext.insert(profile)

            await DataStore.shared.setUserProfile(profile)
            await DataStore.shared.setProfileComplete(true)

            await MainActor.run {
                isLoading = false
                onProfileUpdated?()
            }
        }
    }

    private func saveProfileEdit() {
        isLoading = true
        errorMessage = nil

        Task {
            // Create updated profile
            let profile = UserProfile(
                firstName: firstName.sanitize(),
                lastName: lastName.sanitize(),
                dateOfBirth: dateOfBirth,
                avatarData: avatarImage?.data
            )

            // Save to local storage
            await DataStore.shared.setUserProfile(profile)

            // Update SwiftData
            modelContext.insert(profile)

            await MainActor.run {
                errorMessage = nil
                isLoading = false
                onProfileUpdated?()
                dismiss()
            }
        }
    }

    private func loadProfile() async {
        await MainActor.run { isLoading = true }

        if let profileData = await DataStore.shared.getUserProfile() {
            print("✅ [Profile] Local profile loaded")

            if let avatarData = profileData.avatarData,
               let uiImage = UIImage(data: avatarData) {
                let image = Image(uiImage: uiImage)
                await MainActor.run {
                    self.avatarImage = AvatarImage(image: image, data: avatarData)
                }
            }

            await MainActor.run {
                self.firstName = profileData.firstName
                self.lastName = profileData.lastName
                self.dateOfBirth = profileData.birthDate
                self.isLoading = false
                print("✅ [Profile] Profile state updated")
            }
        } else {
            print("⚠️ [Profile] No local profile found")
            await MainActor.run { isLoading = false }
        }
    }
}

#Preview {
    ProfileSetupView(isSetupMode: true, onProfileUpdated: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
