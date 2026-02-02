import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var birthday: Date?
    @State private var bio = ""
    @State private var isLoading = false

    @State private var imageSelection: PhotosPickerItem?
    @State private var avatarImage: AvatarImage?

    let isSetupMode: Bool
    let onProfileUpdated: (() -> Void)?

    var canSubmit: Bool {
        !name.isEmptyAfterSanitizing
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
                    VStack(spacing: 0) {
                        Form {
                            Section {
                                ProfilePhotoSelector(
                                    imageSelection: $imageSelection,
                                    avatarImage: avatarImage
                                )
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                            }

                            Section {
                                StyledTextField(placeholder: "Name", text: $name)
                                    .listRowSeparator(.hidden)
                                DatePickerField(
                                    title: "Set birthday",
                                    placeholder: "Add birthday",
                                    info: "Your birth year is kept private",
                                    selectedDate: $birthday
                                )
                                    .listRowSeparator(.hidden)
                                StyledTextField(placeholder: "Bio", text: $bio)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .scrollContentBackground(.hidden)

                        if canSubmit {
                            Button(action: saveProfile) {
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text(isSetupMode ? "Continue" : "Save")
                                }
                            }
                            .disabled(isLoading)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .pageBackground()

                }
            }
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

            let profile = UserProfile(
                name: name.sanitize(),
                avatarData: avatarImage?.data,
                birthday: birthday,
                bio: bio.isEmpty ? nil : bio
            )

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

        Task {
            let profile = UserProfile(
                name: name.sanitize(),
                avatarData: avatarImage?.data,
                birthday: birthday,
                bio: bio.isEmpty ? nil : bio
            )

            await DataStore.shared.setUserProfile(profile)
            modelContext.insert(profile)

            await MainActor.run {
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
                self.name = profileData.name
                self.birthday = profileData.birthday
                self.bio = profileData.bio ?? ""
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
