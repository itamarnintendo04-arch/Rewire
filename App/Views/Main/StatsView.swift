import SwiftUI
import DeviceActivity

struct StatsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Screen(title: "Stats") {
            DeviceActivityReport(.week, filter: ReportFilters.week)
                .frame(minHeight: 300)

            HStack(spacing: 12) {
                tile("🔥", "\(model.streak)", "Current streak")
                tile("🏆", "\(model.bestStreak)", "Best streak")
            }
            HStack(spacing: 12) {
                tile("🎯", formatMinutes(model.focusMinutesTotal), "Total focus")
                tile("🛡️", "\(model.blockedOpensToday)", "Blocked today")
            }

            DeviceActivityReport(.today, filter: ReportFilters.today)
                .frame(minHeight: 400)

            if let r = model.quizResult {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where you started").font(.headline).foregroundStyle(.white)
                        Text("You started at \(formatMinutes(r.currentMinutes)) a day with a score of \(r.score)/100.")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Your goal: \(formatMinutes(model.goalMinutes)) a day.")
                            .foregroundStyle(Theme.neon)
                        Text("Compare with the weekly average above to see your progress.")
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
