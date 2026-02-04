import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var birthday: Date?
    @State private var bio = ""

    @State private var imageSelection: PhotosPickerItem?
    @State private var avatarImage: AvatarImage?

    let onProfileUpdated: (() -> Void)?

    var canSubmit: Bool {
        !name.isEmptyAfterSanitizing && birthday != nil && !bio.isEmptyAfterSanitizing
    }

    var body: some View {
        NavigationView {
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
                            title: "Set birthday",
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
                    Button(action: saveProfile) {
                        Text("Continue")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: imageSelection) { _, newValue in
                guard let newValue else { return }
                loadTransferable(from: newValue)
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
        Task {
            let profile = UserProfile(
                name: name.sanitize(),
                avatarData: avatarImage?.data,
                birthday: birthday,
                bio: bio.sanitize()
            )

            modelContext.insert(profile)

            await DataStore.shared.setUserProfile(profile)
            await DataStore.shared.setProfileComplete(true)

            await MainActor.run {
                onProfileUpdated?()
            }
        }
    }
}

#Preview {
    ProfileSetupView(onProfileUpdated: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}
