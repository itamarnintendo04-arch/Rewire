import Foundation
import FamilyControls

/// Single source of truth persisted in the App Group so the app and the
/// extensions (monitor / shield / shield action) all see the same state.
final class SharedStore {
    static let shared = SharedStore()

    let defaults: UserDefaults

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.installDate) == nil {
            defaults.set(Date(), forKey: Keys.installDate)
        }
    }

    private enum Keys {
        static let selection = "selection"
        static let onboarded = "onboarded"
        static let userName = "userName"
        static let userAge = "userAge"
        static let limitEnabled = "limitEnabled"
        static let dailyLimitMinutes = "dailyLimitMinutes"
        static let limitReachedDay = "limitReachedDay"
        static let scheduleEnabled = "scheduleEnabled"
        static let scheduleStart = "scheduleStartMinutes"
        static let scheduleEnd = "scheduleEndMinutes"
        static let sessionEnd = "sessionEnd"
        static let sessionStart = "sessionStart"
        static let unlockUntil = "unlockUntil"
        static let unlockHistory = "unlockHistory"
        static let maxUnlocksPerDay = "maxUnlocksPerDay"
        static let unlockWaitSeconds = "unlockWaitSeconds"
        static let strictMode = "strictMode"
        static let failedDays = "failedDays"
        static let installDate = "installDate"
        static let activeReason = "activeReason"
        static let unlockRequestedAt = "unlockRequestedAt"
        static let quizResult = "quizResult"
        static let blockedOpens = "blockedOpens"
        static let focusMinutesTotal = "focusMinutesTotal"
        static let goalMinutes = "goalMinutes"
    }

    // MARK: - Codable helpers

    private func decode<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T?, _ key: String) {
        if let value, let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Selection

    var selection: FamilyActivitySelection {
        get { decode(Keys.selection) ?? FamilyActivitySelection() }
        set { encode(newValue, Keys.selection) }
    }

    var hasSelection: Bool {
        let s = selection
        return !s.applicationTokens.isEmpty || !s.categoryTokens.isEmpty || !s.webDomainTokens.isEmpty
    }

    // MARK: - Profile

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.onboarded) }
        set { defaults.set(newValue, forKey: Keys.onboarded) }
    }

    var userName: String {
        get { defaults.string(forKey: Keys.userName) ?? "" }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    var userAge: Int {
        get { let v = defaults.integer(forKey: Keys.userAge); return v == 0 ? 18 : v }
        set { defaults.set(newValue, forKey: Keys.userAge) }
    }

    var quizResult: QuizResult? {
        get { decode(Keys.quizResult) }
        set { encode(newValue, Keys.quizResult) }
    }

    /// Daily screen-time goal (all apps). Key is also read by the Report extension.
    var goalMinutes: Int {
        get { let v = defaults.integer(forKey: Keys.goalMinutes); return v == 0 ? 120 : v }
        set { defaults.set(newValue, forKey: Keys.goalMinutes) }
    }

    var installDate: Date {
        defaults.object(forKey: Keys.installDate) as? Date ?? Date()
    }

    // MARK: - Daily limit

    var limitEnabled: Bool {
        get { defaults.object(forKey: Keys.limitEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.limitEnabled) }
    }

    var dailyLimitMinutes: Int {
        get { let v = defaults.integer(forKey: Keys.dailyLimitMinutes); return v == 0 ? 60 : v }
        set { defaults.set(max(1, newValue), forKey: Keys.dailyLimitMinutes) }
    }

    var limitReachedDay: String? {
        get { defaults.string(forKey: Keys.limitReachedDay) }
        set { defaults.set(newValue, forKey: Keys.limitReachedDay) }
    }

    var limitReachedToday: Bool { limitReachedDay == DayKey.today }

    // MARK: - Schedule (minutes from midnight)

    var scheduleEnabled: Bool {
        get { defaults.bool(forKey: Keys.scheduleEnabled) }
        set { defaults.set(newValue, forKey: Keys.scheduleEnabled) }
    }

    var scheduleStartMinutes: Int {
        get { defaults.object(forKey: Keys.scheduleStart) as? Int ?? 22 * 60 }
        set { defaults.set(newValue, forKey: Keys.scheduleStart) }
    }

    var scheduleEndMinutes: Int {
        get { defaults.object(forKey: Keys.scheduleEnd) as? Int ?? 7 * 60 }
        set { defaults.set(newValue, forKey: Keys.scheduleEnd) }
    }

    func isInsideSchedule(_ date: Date = Date()) -> Bool {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let s = scheduleStartMinutes, e = scheduleEndMinutes
        if s == e { return false }
        return s < e ? (m >= s && m < e) : (m >= s || m < e)
    }

    // MARK: - Focus session

    var sessionStart: Date? {
        get { defaults.object(forKey: Keys.sessionStart) as? Date }
        set { defaults.set(newValue, forKey: Keys.sessionStart) }
    }

    var sessionEnd: Date? {
        get { defaults.object(forKey: Keys.sessionEnd) as? Date }
        set { defaults.set(newValue, forKey: Keys.sessionEnd) }
    }

    var focusMinutesTotal: Int {
        get { defaults.integer(forKey: Keys.focusMinutesTotal) }
        set { defaults.set(newValue, forKey: Keys.focusMinutesTotal) }
    }

    // MARK: - Unlocks

    var unlockUntil: Date? {
        get { defaults.object(forKey: Keys.unlockUntil) as? Date }
        set { defaults.set(newValue, forKey: Keys.unlockUntil) }
    }

    var isUnlocked: Bool { (unlockUntil ?? .distantPast) > Date() }

    var unlockHistory: [Date] {
        get { defaults.array(forKey: Keys.unlockHistory) as? [Date] ?? [] }
        set { defaults.set(Array(newValue.suffix(200)), forKey: Keys.unlockHistory) }
    }

    var unlocksToday: Int {
        unlockHistory.filter { Calendar.current.isDateInToday($0) }.count
    }

    var maxUnlocksPerDay: Int {
        get { defaults.object(forKey: Keys.maxUnlocksPerDay) as? Int ?? 3 }
        set { defaults.set(newValue, forKey: Keys.maxUnlocksPerDay) }
    }

    var unlocksLeftToday: Int { max(0, maxUnlocksPerDay - unlocksToday) }

    var unlockWaitSeconds: Int {
        get { defaults.object(forKey: Keys.unlockWaitSeconds) as? Int ?? 15 }
        set { defaults.set(newValue, forKey: Keys.unlockWaitSeconds) }
    }

    /// Strict mode: no unlocks and focus sessions can't be ended early.
    var strictMode: Bool {
        get { defaults.bool(forKey: Keys.strictMode) }
        set { defaults.set(newValue, forKey: Keys.strictMode) }
    }

    var unlockRequestedAt: Date? {
        get { defaults.object(forKey: Keys.unlockRequestedAt) as? Date }
        set { defaults.set(newValue, forKey: Keys.unlockRequestedAt) }
    }

    // MARK: - Status / stats

    var activeReason: BlockReason? {
        get { defaults.string(forKey: Keys.activeReason).flatMap(BlockReason.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Keys.activeReason) }
    }

    /// How many times the user hit a shield (opened a blocked app) per day.
    var blockedOpens: [String: Int] {
        get { defaults.dictionary(forKey: Keys.blockedOpens) as? [String: Int] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.blockedOpens) }
    }

    func recordBlockedOpen() {
        var d = blockedOpens
        d[DayKey.today, default: 0] += 1
        blockedOpens = d
    }

    var blockedOpensToday: Int { blockedOpens[DayKey.today] ?? 0 }

    var failedDays: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.failedDays) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.failedDays) }
    }

    func markFailed(_ day: String = DayKey.today) {
        var s = failedDays
        s.insert(day)
        failedDays = s
    }

    /// Consecutive days (including today) without blowing the daily limit.
    func currentStreak(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let failed = failedDays
        let install = cal.startOfDay(for: installDate)
        var day = cal.startOfDay(for: now)
        var streak = 0
        while day >= install {
            if failed.contains(DayKey.key(for: day)) { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    func bestStreak(now: Date = Date()) -> Int {
        let cal = Calendar.current
        let failed = failedDays
        var day = cal.startOfDay(for: installDate)
        let end = cal.startOfDay(for: now)
        var best = 0, run = 0
        while day <= end {
            if failed.contains(DayKey.key(for: day)) { run = 0 } else { run += 1; best = max(best, run) }
            guard let next = cal.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }
}

/// Summary of the onboarding questionnaire, persisted for the profile screen.
struct QuizResult: Codable, Equatable {
    var score: Int
    var dailyHours: Double
    var age: Int
    var goalHoursSaved: Double
    var topApps: [String]
    var impacts: [String]
    /// Target total daily screen time chosen in the questionnaire.
    var goalMinutes: Int? = nil

    var currentMinutes: Int { Int(dailyHours * 60) }

    static let lifeExpectancy = 80.0

    /// Years of the rest of life that would be spent on the phone.
    var yearsOnPhone: Double {
        dailyHours * max(0, Self.lifeExpectancy - Double(age)) / 24.0
    }

    var yearsRegained: Double {
        goalHoursSaved * max(0, Self.lifeExpectancy - Double(age)) / 24.0
    }
}
