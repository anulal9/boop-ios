import SwiftUI

struct RootView: View {
    @State private var isProfileLoaded: Bool? = nil

    private func checkProfileExists() {
        Task {
            let profile = await DataStore.shared.getUserProfile()
            isProfileLoaded = (profile != nil)
        }
    }

    var body: some View {
        Group {
            if let isProfileLoaded = isProfileLoaded {
                if isProfileLoaded {
                    MainTabView()
                } else {
                    ProfileSetupView(onProfileUpdated: {
                        self.isProfileLoaded = true
                    })
                }
            } else {
                // Loading indicator while checking profile
                ProgressView().onAppear(perform: checkProfileExists)
            }
        }.pageBackground()
    }
}

#Preview {
    RootView()
}
