import Foundation
import Combine
import FamilyControls
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    private let store = SharedStore.shared
    private var cancellables = Set<AnyCancellable>()

    // Onboarding / profile
    @Published var hasOnboarded: Bool
    @Published var userName: String { didSet { store.userName = userName } }
    @Published var userAge: Int { didSet { store.userAge = userAge; quiz.age = userAge } }
    @Published var quiz = QuizState()
    @Published var quizResult: QuizResult?

    // Screen Time
    @Published private(set) var authStatus: AuthorizationStatus = AuthorizationCenter.shared.authorizationStatus
    @Published var selection: FamilyActivitySelection {
        didSet { store.selection = selection; ActivityScheduler.refreshAll(); refresh() }
    }

    // Rules
    @Published var limitEnabled: Bool { didSet { store.limitEnabled = limitEnabled; ActivityScheduler.refreshAll(); refresh() } }
    @Published var dailyLimitMinutes: Int { didSet { store.dailyLimitMinutes = dailyLimitMinutes } }
    @Published var scheduleEnabled: Bool { didSet { store.scheduleEnabled = scheduleEnabled; ActivityScheduler.refreshAll(); refresh() } }
    @Published var scheduleStart: Date { didSet { store.scheduleStartMinutes = scheduleStart.minutesFromMidnight } }
    @Published var scheduleEnd: Date { didSet { store.scheduleEndMinutes = scheduleEnd.minutesFromMidnight } }
    @Published var maxUnlocksPerDay: Int { didSet { store.maxUnlocksPerDay = maxUnlocksPerDay } }
    @Published var unlockWaitSeconds: Int { didSet { store.unlockWaitSeconds = unlockWaitSeconds } }
    @Published var strictMode: Bool { didSet { store.strictMode = strictMode } }
    @Published var goalMinutes: Int { didSet { store.goalMinutes = goalMinutes } }

    // Live status
    @Published private(set) var activeReason: BlockReason?
    @Published private(set) var sessionEnd: Date?
    @Published private(set) var unlockUntil: Date?
    @Published private(set) var streak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var unlocksLeft = 0
    @Published private(set) var blockedOpensToday = 0
    @Published private(set) var focusMinutesTotal = 0
    @Published var showUnlockFlow = false
    @Published var errorMessage: String?
    /// Detailed reason the last Screen Time request failed (shown on the permission screen).
    @Published var authFailureReason: String?

    init() {
        hasOnboarded = store.hasOnboarded
        userName = store.userName
        userAge = store.userAge
        quizResult = store.quizResult
        selection = store.selection
        limitEnabled = store.limitEnabled
        dailyLimitMinutes = store.dailyLimitMinutes
        scheduleEnabled = store.scheduleEnabled
        scheduleStart = Date.fromMinutes(store.scheduleStartMinutes)
        scheduleEnd = Date.fromMinutes(store.scheduleEndMinutes)
        maxUnlocksPerDay = store.maxUnlocksPerDay
        unlockWaitSeconds = store.unlockWaitSeconds
        strictMode = store.strictMode
        goalMinutes = store.goalMinutes

        AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.authStatus = $0 }
            .store(in: &cancellables)

        refresh()
    }

    var isAuthorized: Bool { authStatus == .approved }

    var selectionCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    // MARK: - Status

    /// Pull the latest shared state (extensions may have changed it).
    func refresh() {
        if store.unlockUntil.map({ $0 <= Date() }) == true { store.unlockUntil = nil }
        if store.sessionEnd.map({ $0 <= Date() }) == true {
            if let s = store.sessionStart, let e = store.sessionEnd {
                store.focusMinutesTotal += max(0, Int(e.timeIntervalSince(s) / 60))
            }
            store.sessionEnd = nil
            store.sessionStart = nil
        }
        if isAuthorized { ShieldController.reconcile() }

        activeReason = store.activeReason
        sessionEnd = store.sessionEnd
        unlockUntil = store.unlockUntil
        streak = store.currentStreak()
        bestStreak = store.bestStreak()
        unlocksLeft = store.unlocksLeftToday
        blockedOpensToday = store.blockedOpensToday
        focusMinutesTotal = store.focusMinutesTotal

        if let requested = store.unlockRequestedAt, Date().timeIntervalSince(requested) < 300, activeReason != nil {
            store.unlockRequestedAt = nil
            showUnlockFlow = true
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        authFailureReason = nil
        if ScreenTimeDiagnostics.profileHasFamilyControls == false {
            // iOS would reject the request without showing any dialog.
            authFailureReason = ScreenTimeDiagnostics.missingEntitlementMessage
            return false
        }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Screen Time authorization error: \(error)")
            authFailureReason = ScreenTimeDiagnostics.message(for: error)
        }
        authStatus = AuthorizationCenter.shared.authorizationStatus
        if isAuthorized {
            authFailureReason = nil
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } else if authFailureReason == nil {
            authFailureReason = "Screen Time access wasn't granted. Tap the button and choose \"Continue\" in Apple's dialog."
        }
        return isAuthorized
    }

    // MARK: - Onboarding

    func finishQuiz() {
        quiz.age = userAge
        let r = quiz.result
        quizResult = r
        store.quizResult = r
        goalMinutes = quiz.goalMinutes
        // Distracting apps get half of the total goal.
        let suggested = (quiz.goalMinutes / 2) / 15 * 15
        dailyLimitMinutes = min(240, max(15, suggested))
    }

    func completeOnboarding() {
        store.hasOnboarded = true
        hasOnboarded = true
        ActivityScheduler.refreshAll()
        refresh()
    }

    func resetOnboarding() {
        store.hasOnboarded = false
        quiz = QuizState()
        hasOnboarded = false
    }

    /// Apply limit / schedule edits (called after the user finishes editing).
    func applyRules() {
        ActivityScheduler.refreshAll()
        refresh()
    }

    // MARK: - Focus session

    func startSession(minutes: Int) {
        guard store.hasSelection else {
            errorMessage = "Choose apps to block first."
            return
        }
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        do {
            try ActivityScheduler.scheduleOneShot(.session, until: end)
            store.sessionStart = Date()
            store.sessionEnd = end
            store.unlockUntil = nil
            ActivityScheduler.stop(.unlock)
            refresh()
        } catch {
            errorMessage = "Couldn't start the session: \(error.localizedDescription)"
        }
    }

    var canEndSessionEarly: Bool { !strictMode }

    func endSessionEarly() {
        guard canEndSessionEarly else { return }
        ActivityScheduler.stop(.session)
        store.sessionEnd = nil
        store.sessionStart = nil
        refresh()
    }

    // MARK: - Unlock

    var canUnlock: Bool {
        !strictMode && unlocksLeft > 0 && activeReason != nil && activeReason != .session
    }

    func unlock(minutes: Int) {
        guard canUnlock else { return }
        let end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        do {
            try ActivityScheduler.scheduleOneShot(.unlock, until: end)
            store.unlockUntil = end
            store.unlockHistory = store.unlockHistory + [Date()]
            ShieldController.clear()
            refresh()
        } catch {
            errorMessage = "Couldn't unlock: \(error.localizedDescription)"
        }
    }

    func relockNow() {
        ActivityScheduler.stop(.unlock)
        store.unlockUntil = nil
        refresh()
    }
}

extension Date {
    var minutesFromMidnight: Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: self)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func fromMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    }
}

func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60, m = minutes % 60
    if h == 0 { return "\(m) min" }
    return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
}
