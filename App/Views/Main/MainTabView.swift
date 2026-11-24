import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("בית", systemImage: "house.fill") }
            FocusView()
                .tabItem { Label("פוקוס", systemImage: "lock.fill") }
            StatsView()
                .tabItem { Label("סטטיסטיקה", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("הגדרות", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $model.showUnlockFlow) {
            UnlockFlowView()
                .environmentObject(model)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = UIColor(Theme.bg).withAlphaComponent(0.92)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

/// A common screen wrapper with the background and large title.
struct Screen<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) { content }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle(title)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
