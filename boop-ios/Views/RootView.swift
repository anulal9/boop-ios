import SwiftUI
import SwiftData

struct RootView: View {
    @Binding var selectedTab: Int
    @Binding var selectedInteractionID: UUID?
    @Binding var selectedContactID: UUID?

    var body: some View {
        Group {
            MainTabView(
                selectedTab: $selectedTab,
                selectedInteractionID: $selectedInteractionID,
                selectedContactID: $selectedContactID
            )
        }
        .pageBackground()
    }
}

#Preview {
    RootView(selectedTab: .constant(0), selectedInteractionID: .constant(nil), selectedContactID: .constant(nil))
}
