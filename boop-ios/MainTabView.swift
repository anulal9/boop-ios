import SwiftUI

/// Root tab view for authenticated users
struct MainTabView: View {
    var body: some View {
        TabView {
            BoopTimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }

            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }

            ProfileView()
            .tabItem {
                Label("You", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    MainTabView()
}
