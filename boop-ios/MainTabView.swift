import SwiftUI

/// Root tab view for authenticated users
struct MainTabView: View {
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        TabView {
            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }

            ProfileSetupView(
                isSetupMode: false,
                onProfileUpdated: {
                    refreshTrigger = UUID()
                }
            )
            .id(refreshTrigger)
            .tabItem {
                Label("You", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    MainTabView()
}
