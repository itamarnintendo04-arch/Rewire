import Foundation
import DeviceActivity
import ManagedSettings

/// App Group shared between the app and all extensions.
/// Change this (and the entitlements in project.yml) to your own group id.
enum AppGroup {
    static let id = "group.com.example.rewire"
    static let defaults: UserDefaults = UserDefaults(suiteName: id) ?? .standard
}

extension DeviceActivityName {
    /// Repeats every day 00:00–23:59, carries the daily-limit events.
    static let daily = Self("rewire.daily")
    /// Repeating bedtime / focus schedule chosen by the user.
    static let schedule = Self("rewire.schedule")
    /// One-shot: a "block now" focus session. Its end clears the session.
    static let session = Self("rewire.session")
    /// One-shot: a temporary unlock. Its end re-applies the shield.
    static let unlock = Self("rewire.unlock")
}

extension DeviceActivityEvent.Name {
    static let limitReached = Self("rewire.limit.reached")
    static let limitWarning = Self("rewire.limit.warning")
}

extension ManagedSettingsStore.Name {
    static let rewire = Self("rewire")
}

/// Why apps are currently shielded.
enum BlockReason: String, Codable {
    case session
    case limit
    case schedule

    var title: String {
        switch self {
        case .session: return "סשן פוקוס פעיל"
        case .limit: return "הגעת למגבלה היומית"
        case .schedule: return "זמן חסימה מתוזמן"
        }
    }

    var emoji: String {
        switch self {
        case .session: return "🎯"
        case .limit: return "⏰"
        case .schedule: return "🌙"
        }
    }
}

enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String {
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    static var today: String { key(for: Date()) }
}
