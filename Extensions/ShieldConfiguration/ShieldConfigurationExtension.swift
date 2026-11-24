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
        "המוח שלך שווה יותר מעוד סרטון.",
        "הגלילה הבאה לא תשנה לך את החיים. מה כן?",
        "כל פעם שאת/ה לא פותח/ת – המוח נבנה מחדש.",
        "שעה ביום = 3 שנים מהחיים. תבחר/י בהן.",
        "הדבר הכי מעניין עכשיו נמצא מחוץ למסך.",
        "את/ה שולט/ת בטלפון. לא הוא בך.",
        "נשימה עמוקה. מה באמת חיפשת?",
    ]

    private func make(name: String?) -> ShieldConfiguration {
        let store = SharedStore.shared
        store.recordBlockedOpen()

        let reason = store.activeReason ?? .limit
        let appName = name ?? "האפליקציה הזו"
        let quote = Self.quotes.randomElement() ?? Self.quotes[0]

        var subtitle = "\(appName) חסומה – \(reason.title).\n\n\"\(quote)\""
        if reason == .session, let end = store.sessionEnd {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            subtitle += "\n\nהסשן נגמר ב-\(f.string(from: end))"
        }

        let opens = store.blockedOpensToday
        if opens > 1 {
            subtitle += "\nניסית לפתוח אפליקציות חסומות \(opens) פעמים היום."
        }

        let requested = (store.unlockRequestedAt.map { Date().timeIntervalSince($0) < 120 }) ?? false
        let canUnlock = !store.strictMode && store.unlocksLeftToday > 0 && reason != .session

        let secondary: ShieldConfiguration.Label?
        if requested {
            secondary = .init(text: "📲 לחצ/י על ההתראה", color: .lightGray)
        } else if canUnlock {
            secondary = .init(text: "אני צריך/ה עוד כמה דקות (\(store.unlocksLeftToday))", color: .lightGray)
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
            title: .init(text: "\(reason.emoji) רגע, עצור/י", color: .white),
            subtitle: .init(text: subtitle, color: UIColor(white: 0.85, alpha: 1)),
            primaryButtonLabel: .init(text: "סגור – חוזר/ת לחיים", color: .white),
            primaryButtonBackgroundColor: accent,
            secondaryButtonLabel: secondary
        )
    }
}
