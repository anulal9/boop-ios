import SwiftUI

struct DisplayColorPickerSheet: View {
    @Binding var gradientColors: [Color]
    @State private var selectedColors: [Color] = []

    @Environment(\.dismiss) private var dismiss

    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .indigo, .purple, .pink,
        .mint, .teal, .brown, .black, .gray
    ]

    init(gradientColors: Binding<[Color]>) {
        self._gradientColors = gradientColors
        // Extract the two unique colors from the gradient
        _selectedColors = State(initialValue: Array(Set(gradientColors.wrappedValue)).prefix(2).map { $0 })
    }

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .center), count: 5), spacing: Spacing.lg) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: {
                            toggleColorSelection(color)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 60, height: 60)

                                if selectedColors.contains(color) {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()

                Spacer()
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
        .presentationDetents([.height(300)])
    }

    private func toggleColorSelection(_ color: Color) {
        if let index = selectedColors.firstIndex(of: color) {
            selectedColors.remove(at: index)
        } else if selectedColors.count < 2 {
            selectedColors.append(color)
        } else {
            selectedColors[0] = selectedColors[1]
            selectedColors[1] = color
        }
        if selectedColors.count == 2 {
            gradientColors = (0..<9).map { selectedColors[$0 % 2] }
        }
    }
}

#Preview {
    DisplayColorPickerSheet(gradientColors: .constant([.pink, .purple]))
}
