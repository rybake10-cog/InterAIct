import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Group {
            if settings.avatar == nil {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .fontDesign(.rounded)
        .tint(Color(hex: "#4F7CAC"))
        .preferredColorScheme(.light)
    }
}
