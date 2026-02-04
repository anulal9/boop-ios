import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var birthday: Date?
    @State private var bio = ""
    @State private var isLoading = false
    @State private var isEditing = false

    @State private var imageSelection: PhotosPickerItem?
    @State private var avatarImage: AvatarImage?

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
                    if isEditing {
                        editModeView
                    } else {
                        displayModeView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditing && !isLoading {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
            .onChange(of: imageSelection) { _, newValue in
                guard let newValue else { return }
                loadTransferable(from: newValue)
            }
            .task {
                await loadProfile()
            }
        }
        .pageBackground()
    }
    
    private var displayModeView: some View {
        Form {
            Section {
                ProfileDisplayCard(
                    avatarImage: avatarImage?.image,
                    displayName: name,
                    birthday: birthday,
                    bio: bio.isEmpty ? nil : bio
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .scrollContentBackground(.hidden)
        .pageBackground()
    }
    
    private var editModeView: some View {
        ZStack(alignment: .bottom) {
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
                        title: "Birthday",
                        placeholder: "Add birthday",
                        info: "Your birth year is kept private",
                        selectedDate: $birthday
                    )
                    .listRowSeparator(.hidden)
                    StyledTextField(placeholder: "Bio", text: $bio)
                        .listRowSeparator(.hidden)
                }
                
                Section {
                    Color.clear
                        .frame(height: 80)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            if canSubmit {
                VStack {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isLoading)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color(uiColor: .systemBackground))
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .pageBackground()
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
                isEditing = false
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
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
