import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
    static let today = Self("today")
    static let week = Self("week")
}

enum ReportFilters {
    static var today: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: Date())
            ?? DateInterval(start: Calendar.current.startOfDay(for: Date()), duration: 86_400)
        return DeviceActivityFilter(segment: .daily(during: interval),
                                    users: .all,
                                    devices: .init([.iPhone, .iPad]))
    }

    static var week: DeviceActivityFilter {
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: end)) ?? end
        return DeviceActivityFilter(segment: .daily(during: DateInterval(start: start, end: end)),
                                    users: .all,
                                    devices: .init([.iPhone, .iPad]))
    }
}

struct HomeView: View {
    @EnvironmentObject var model: AppModel
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Screen(title: greeting) {
            statusCard
            streakRow
            DeviceActivityReport(.today, filter: ReportFilters.today)
                .frame(minHeight: 380)
            quickActions
            if let r = model.quizResult { scoreCard(r) }
        }
        .onReceive(ticker) { t in
            now = t
            if let end = model.sessionEnd, end <= t { model.refresh() }
            if let end = model.unlockUntil, end <= t { model.refresh() }
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let part = h < 12 ? "בוקר טוב" : (h < 18 ? "צהריים טובים" : "ערב טוב")
        return model.userName.isEmpty ? part : "\(part), \(model.userName)"
    }

    // MARK: Status

    @ViewBuilder private var statusCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                if let until = model.unlockUntil, until > now {
                    statusHeader("🔓", "שחרור זמני", Theme.warning)
                    Text("נועל שוב בעוד \(countdown(to: until))")
                        .font(.system(size: 28, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Button("נעל עכשיו") { model.relockNow() }
                        .buttonStyle(SecondaryButtonStyle())
                } else if let reason = model.activeReason {
                    statusHeader(reason.emoji, reason.title, Theme.danger)
                    if reason == .session, let end = model.sessionEnd {
                        Text(countdown(to: end))
                            .font(.system(size: 40, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(.white)
                    } else {
                        Text("\(model.selectionCount) פריטים חסומים כרגע")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    if model.canUnlock {
                        Button("צריך/ה כמה דקות? (\(model.unlocksLeft) נשארו)") { model.showUnlockFlow = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                } else {
                    statusHeader("✅", "הכל פתוח כרגע", Theme.neon)
                    Text(model.limitEnabled
                         ? "מגבלה יומית: \(formatMinutes(model.dailyLimitMinutes)) באפליקציות שבחרת"
                         : "אין מגבלה יומית פעילה")
                        .foregroundStyle(.white.opacity(0.7))
                }

                if !model.isAuthorized {
                    Label("אין הרשאת זמן מסך – החסימה לא תעבוד", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold)).foregroundStyle(Theme.warning)
                }
            }
        }
    }

    private func statusHeader(_ emoji: String, _ title: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.title2)
            Text(title).font(.headline).foregroundStyle(color)
            Spacer()
        }
    }

    // MARK: Streak

    private var streakRow: some View {
        HStack(spacing: 12) {
            statTile(icon: "flame.fill", color: .orange, value: "\(model.streak)", label: "ימי רצף")
            statTile(icon: "trophy.fill", color: .yellow, value: "\(model.bestStreak)", label: "שיא")
            statTile(icon: "hand.raised.fill", color: Theme.accent, value: "\(model.blockedOpensToday)", label: "נחסמו היום")
        }
    }

    private func statTile(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.stroke))
    }

    // MARK: Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("פוקוס מהיר").font(.headline).foregroundStyle(.white)
            HStack(spacing: 10) {
                ForEach([25, 60, 120], id: \.self) { m in
                    Button {
                        hapticTap(.medium)
                        model.startSession(minutes: m)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                            Text(formatMinutes(m)).font(.subheadline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.accent.opacity(0.18)))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.accent.opacity(0.5)))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(model.sessionEnd != nil)
                }
            }
        }
    }

    private func scoreCard(_ r: QuizResult) -> some View {
        Card {
            HStack(spacing: 16) {
                ScoreRing(score: r.score, size: 80)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ציון ה-Brain Rot ההתחלתי").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                    Text(r.verdict.title).font(.headline).foregroundStyle(.white)
                    Text("המטרה: להחזיר \(String(format: "%.1f", r.yearsRegained)) שנים לחיים")
                        .font(.caption).foregroundStyle(Theme.neon)
                }
            }
        }
    }

    private func countdown(to date: Date) -> String {
        let s = max(0, Int(date.timeIntervalSince(now)))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
    }
}
