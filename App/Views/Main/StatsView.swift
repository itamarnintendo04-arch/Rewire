import SwiftUI
import DeviceActivity

struct StatsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Screen(title: "סטטיסטיקה") {
            DeviceActivityReport(.week, filter: ReportFilters.week)
                .frame(minHeight: 300)

            HStack(spacing: 12) {
                tile("🔥", "\(model.streak)", "רצף נוכחי")
                tile("🏆", "\(model.bestStreak)", "רצף שיא")
            }
            HStack(spacing: 12) {
                tile("🎯", formatMinutes(model.focusMinutesTotal), "בפוקוס סה״כ")
                tile("🛡️", "\(model.blockedOpensToday)", "ניסיונות נחסמו היום")
            }

            DeviceActivityReport(.today, filter: ReportFilters.today)
                .frame(minHeight: 380)

            if let r = model.quizResult {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ההתחלה שלך").font(.headline).foregroundStyle(.white)
                        Text("התחלת עם \(formatMinutes(Int(r.dailyHours * 60))) ביום וציון \(r.score)/100.")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("השווה/י לממוצע השבועי למעלה כדי לראות את ההתקדמות.")
                            .font(.footnote).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private func tile(_ emoji: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.title2)
            Text(value).font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.stroke))
    }
}
