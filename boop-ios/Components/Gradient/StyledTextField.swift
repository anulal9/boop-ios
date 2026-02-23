import SwiftUI

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.textPrimary.opacity(0.6)), axis: .vertical)
            .foregroundColor(.textPrimary)
            .tint(.textPrimary)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .padding(Spacing.md)
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadius.lg)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.textPrimary.opacity(0.2), lineWidth: 1)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .frame(minHeight: 44)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}
