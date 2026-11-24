import SwiftUI

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            AppBackground()
            if model.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: model.hasOnboarded)
        .alert("שגיאה", isPresented: Binding(get: { model.errorMessage != nil },
                                              set: { if !$0 { model.errorMessage = nil } })) {
            Button("אישור", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
