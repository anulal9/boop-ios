import SwiftUI

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    // Text field specific gradient styling
    private let gradientColors: [Color] = [
        .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6),
        .pink.opacity(0.6), .indigo.opacity(0.7), .teal.opacity(0.6),
        .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6)
    ]
    private let gradientAnimationStyle: AnimatedMeshGradient.AnimationStyle = .verticalWave
    private let gradientDuration: Double = 3.0

    var body: some View {
        ZStack(alignment: .center) {
            // Background layer
            if isFocused {
                AnimatedMeshGradient(
                    colors: gradientColors,
                    animationStyle: gradientAnimationStyle,
                    duration: gradientDuration
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.formBackgroundInactive)
            }

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white), axis: .vertical)
                .foregroundStyle(.white)
                .tint(.white)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .padding(12)
        }
                    .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        .frame(minHeight: 44)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}
