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

    init() {
        hasOnboarded = store.hasOnboarded
        userName = store.userName
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
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authStatus = AuthorizationCenter.shared.authorizationStatus
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return isAuthorized
        } catch {
            errorMessage = "לא הצלחנו להתחבר לזמן מסך: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Onboarding

    func finishQuiz() {
        let r = quiz.result
        quizResult = r
        store.quizResult = r
        // Suggest a limit based on the goal.
        let suggested = Int(((r.dailyHours - r.goalHoursSaved) * 60 / 2).rounded() / 15) * 15
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
            errorMessage = "קודם צריך לבחור אפליקציות לחסימה."
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
            errorMessage = "לא הצלחנו להתחיל סשן: \(error.localizedDescription)"
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
            errorMessage = "לא הצלחנו לשחרר: \(error.localizedDescription)"
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
    if h == 0 { return "\(m) דק׳" }
    return m == 0 ? "\(h) שע׳" : "\(h) שע׳ \(m) דק׳"
}
