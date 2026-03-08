import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var birthday: Date?
    @State private var bio: String

    @State private var isLoading = false
    @State private var gradientColors: [Color] = []
    @State private var selectedColors: [Color] = []

    let buttonText: String
    let requireAllFields: Bool
    let isEditMode: Bool
    let onSave: (UserProfile) -> Void
    
    init(
        initialName: String = "",
        initialBirthday: Date? = nil,
        initialBio: String = "",
        buttonText: String = "Continue",
        requireAllFields: Bool = true,
        isEditMode: Bool = false,
        gradientColors: [Color]? = nil,
        onSave: @escaping (UserProfile) -> Void
    ) {
        _name = State(initialValue: initialName)
        _birthday = State(initialValue: initialBirthday)
        _bio = State(initialValue: initialBio)
        let colors = gradientColors ?? ProfileSetupView.generateRandomGradient()
        _gradientColors = State(initialValue: colors)
        // Extract the two unique colors from the gradient pattern
        _selectedColors = State(initialValue: Array(Set(colors)).sorted(by: { colors.firstIndex(of: $0)! < colors.firstIndex(of: $1)! }))
        self.buttonText = buttonText
        self.requireAllFields = requireAllFields
        self.isEditMode = isEditMode
        self.onSave = onSave
    }

    var canSubmit: Bool {
        if requireAllFields {
            return !name.isEmptyAfterSanitizing && birthday != nil && !bio.isEmptyAfterSanitizing
        } else {
            return !name.isEmptyAfterSanitizing
        }
    }
    
    private static func generateRandomGradient() -> [Color] {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .cyan, .blue, .indigo, .purple, .pink,
            .mint, .teal, .brown, .white, .black, .gray
        ]
        let firstColor = colors.randomElement()!
        let secondColor = colors.filter { $0 != firstColor }.randomElement()!
        let selectedColors = [firstColor, secondColor]
        return (0..<9).map { selectedColors[$0 % 2] }
    }

    var body: some View {
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
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button {
                    saveProfile()
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(buttonText)
                    }
                }
                .disabled(!canSubmit || isLoading)
            }
        }
    }
}

    private func saveProfile() {
        isLoading = true
        
        let profile = UserProfile(
            name: name.sanitize(),
            birthday: birthday,
            bio: bio.isEmpty ? nil : bio.sanitize(),
            gradientColors: gradientColors
        )
        
        onSave(profile)
        
        isLoading = false
    }
    
    private func updateGradient() {
        guard selectedColors.count == 2 else { return }
        gradientColors = (0..<9).map { selectedColors[$0 % 2] }
    }
}

#Preview {
    ProfileSetupView(onSave: { _ in })
        .modelContainer(for: UserProfile.self, inMemory: true)
}
