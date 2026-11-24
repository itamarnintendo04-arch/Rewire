import SwiftUI
import UserNotifications

@main
struct RewireApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .onReceive(NotificationCenter.default.publisher(for: .rewireOpenUnlock)) { _ in
                    model.refresh()
                    if model.activeReason != nil { model.showUnlockFlow = true }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.refresh() }
        }
    }
}

extension Notification.Name {
    static let rewireOpenUnlock = Notification.Name("rewire.openUnlock")
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        if response.notification.request.content.categoryIdentifier == Notifier.unlockCategory {
            await MainActor.run {
                NotificationCenter.default.post(name: .rewireOpenUnlock, object: nil)
            }
        }
    }
}
