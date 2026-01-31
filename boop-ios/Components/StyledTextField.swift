import SwiftUI

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .center) {
            // Background layer with fixed shape
            RoundedRectangle(cornerRadius: 22)
                .fill(isFocused ? Color.clear : Color.formBackgroundInactive)
                .frame(height: 44)

            if isFocused {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.clear)
                    .frame(height: 44)
                    .background(
                        AnimatedTextFieldMeshGradient()
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    )
            }

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white))
                .foregroundStyle(.white)
                .tint(.white)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .frame(height: 44)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}
