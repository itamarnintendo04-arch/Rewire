import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the custom screen that appears instead of a blocked app.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        make(name: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        make(name: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        make(name: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        make(name: webDomain.domain)
    }

    // MARK: -

    private static let quotes = [
        "Your brain is worth more than another video.",
        "The next scroll won't change your life. What will?",
        "Every time you don't open it, your brain rewires.",
        "One hour a day = 3 years of your life. Choose them.",
        "The most interesting thing right now is off-screen.",
        "You control your phone. Not the other way around.",
        "Take a deep breath. What were you really looking for?",
    ]

    private func make(name: String?) -> ShieldConfiguration {
        let store = SharedStore.shared
        store.recordBlockedOpen()

        let reason = store.activeReason ?? .limit
        let appName = name ?? "This app"
        let quote = Self.quotes.randomElement() ?? Self.quotes[0]

        var subtitle = "\(appName) is blocked – \(reason.title).\n\n\"\(quote)\""
        if reason == .session, let end = store.sessionEnd {
            let f = DateFormatter()
            f.timeStyle = .short
            subtitle += "\n\nSession ends at \(f.string(from: end))"
        }

        let opens = store.blockedOpensToday
        if opens > 1 {
            subtitle += "\nYou've tried to open blocked apps \(opens) times today."
        }

        let requested = (store.unlockRequestedAt.map { Date().timeIntervalSince($0) < 120 }) ?? false
        let canUnlock = !store.strictMode && store.unlocksLeftToday > 0 && reason != .session

        let secondary: ShieldConfiguration.Label?
        if requested {
            secondary = .init(text: "📲 Tap the notification", color: .lightGray)
        } else if canUnlock {
            secondary = .init(text: "I need a few minutes (\(store.unlocksLeftToday) left)", color: .lightGray)
        } else {
            secondary = nil
        }

        let accent = UIColor(red: 0.62, green: 0.35, blue: 1.0, alpha: 1)
        let icon = UIImage(systemName: "brain.head.profile")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 60, weight: .bold))
            .withTintColor(accent, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.05, green: 0.04, blue: 0.10, alpha: 0.92),
            icon: icon,
            title: .init(text: "\(reason.emoji) Hold on", color: .white),
            subtitle: .init(text: subtitle, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: .init(text: "Close – back to life", color: .white),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: secondary
        )
    }
}
