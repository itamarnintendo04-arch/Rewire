import ManagedSettings
import Foundation

/// Handles taps on the shield buttons.
/// Primary   -> close the blocked app.
/// Secondary -> ask for an unlock: an extension can't open the host app,
///              so we post a notification that deep-links into the unlock flow.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    private func respond(to action: ShieldAction,
                         _ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)

        case .secondaryButtonPressed:
            let store = SharedStore.shared
            store.unlockRequestedAt = Date()
            Notifier.send(title: "🔓 Unlock request",
                          body: "Tap here to open Rewire and ask for a few minutes.",
                          id: "unlock.request",
                          category: Notifier.unlockCategory)
            // .defer re-renders the shield so it shows "tap the notification".
            completionHandler(.defer)

        @unknown default:
            completionHandler(.close)
        }
    }
}
