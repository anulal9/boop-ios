import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var birthday: Date?
    @State private var bio = ""
    @State private var isLoading = false
    @State private var isEditing = false
    @State private var isEditingDisplay = false

    @State private var gradientColors: [Color] = []
    @State private var showColorPicker = false

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
                    if isEditing {
                        editModeView
                    } else if isEditingDisplay {
                        editDisplayModeView
                    } else {
                        displayModeView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditing && !isEditingDisplay && !isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Customize") {
                            isEditingDisplay = true
                        }
                    }
                } else if isEditingDisplay {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            saveDisplayChanges()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            cancelDisplayChanges()
                        }
                    }
                }
            }
            .task {
                await loadProfile()
            }
        }
        .pageBackground()
    }
    
    private var displayModeView: some View {
        NavigationView {
            ZStack {
                AnimatedMeshGradient(
                    colors: gradientColors,
                    animationStyle: .horizontalWave,
                    duration: 3.0
                )
                .ignoresSafeArea()
                
                Form {
                    Section {
                        ProfileDisplayCard(
                            displayName: name,
                            birthday: birthday,
                            bio: bio.isEmpty ? nil : bio
                        )
                    }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var editModeView: some View {
        ProfileSetupView(
            initialName: name,
            initialBirthday: birthday,
            initialBio: bio,
            buttonText: "Save",
            requireAllFields: false,
            isEditMode: true,
            gradientColors: gradientColors,
            onSave: { profile in
                saveProfile(profile: profile)
            }
        )
    }
    
    private var editDisplayModeView: some View {
        NavigationView {
            ZStack {
                AnimatedMeshGradient(
                    colors: gradientColors,
                    animationStyle: .horizontalWave,
                    duration: 3.0
                )
                .ignoresSafeArea()
                
                VStack {
                    Form {
                        Section {
                            ProfileDisplayCard(

                                displayName: name,
                                birthday: birthday,
                                bio: bio.isEmpty ? nil : bio
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                    .scrollContentBackground(.hidden)
                    
                    // Display customization controls
                    VStack(spacing: Spacing.lg) {
                        Button(action: {
                            showColorPicker = true
                        }) {
                            HStack {
                                Text("Gradient Colors")
                                    .foregroundColor(.textPrimary)
                                    .font(.headline)
                                Spacer()
                                HStack(spacing: Spacing.xs) {
                                    ForEach(Array(Set(gradientColors)).prefix(2), id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(CornerRadius.lg)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .sheet(isPresented: $showColorPicker) {
                DisplayColorPickerSheet(gradientColors: $gradientColors)
            }
        }
    }
    
    private func saveDisplayChanges() {
        Task {
            if let profileData = await DataStore.shared.getUserProfile() {
                let profile = UserProfile(
                    name: profileData.name,
                    birthday: profileData.birthday,
                    bio: profileData.bio,
                    gradientColors: gradientColors
                )
                await DataStore.shared.setUserProfile(profile)
                modelContext.insert(profile)
            }
            await MainActor.run {
                isEditingDisplay = false
            }
        }
    }
    
    private func cancelDisplayChanges() {
        // Reload original gradient colors
        Task {
            await loadProfile()
            await MainActor.run {
                isEditingDisplay = false
            }
        }
    }

    private func saveProfile(profile: UserProfile) {
        isLoading = true

        Task {
            await DataStore.shared.setUserProfile(profile)
            modelContext.insert(profile)

            await MainActor.run {
                // Update local state
                self.name = profile.name
                self.birthday = profile.birthday
                self.bio = profile.bio ?? ""
                self.gradientColors = profile.gradientColors
                
                self.isLoading = false
                self.isEditing = false
            }
        }
    }

    private func loadProfile() async {
        await MainActor.run { isLoading = true }

        if let profileData = await DataStore.shared.getUserProfile() {
            print("✅ [Profile] Local profile loaded")

            await MainActor.run {
                self.name = profileData.name
                self.birthday = profileData.birthday
                self.bio = profileData.bio ?? ""
                self.gradientColors = profileData.gradientColors
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
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
