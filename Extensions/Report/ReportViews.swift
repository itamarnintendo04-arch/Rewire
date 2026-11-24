import SwiftUI
import Charts
import FamilyControls

private let accent = Color(red: 0.62, green: 0.35, blue: 1.0)
private let neon = Color(red: 0.30, green: 1.0, blue: 0.60)
private let card = Color.white.opacity(0.06)

struct TodayReportView: View {
    let report: TodayData

    /// Written by the app (SharedStore.goalMinutes) in the shared App Group.
    private var goalMinutes: Int {
        let v = UserDefaults(suiteName: "group.com.example.rewire")?.integer(forKey: "goalMinutes") ?? 0
        return v == 0 ? 120 : v
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("זמן מסך היום")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(formatDuration(report.total))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("הרמות").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(report.pickups)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(neon)
                }
            }

            goalProgress

            if report.apps.isEmpty {
                Text("עוד אין נתונים להיום")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let maxDuration = report.apps.first?.duration ?? 1
                VStack(spacing: 12) {
                    ForEach(report.apps) { app in
                        HStack(spacing: 12) {
                            if let token = app.token {
                                Label(token).labelStyle(.iconOnly)
                                    .frame(width: 30, height: 30)
                            } else {
                                Image(systemName: "app.fill").frame(width: 30, height: 30)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(app.name).font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white).lineLimit(1)
                                    Spacer()
                                    Text(formatDuration(app.duration))
                                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                }
                                GeometryReader { geo in
                                    Capsule().fill(Color.white.opacity(0.08))
                                        .overlay(alignment: .leading) {
                                            Capsule().fill(LinearGradient(colors: [accent, neon],
                                                                          startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * CGFloat(app.duration / max(maxDuration, 1)))
                                        }
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(card))
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
    }

    private var goalProgress: some View {
        let goal = TimeInterval(goalMinutes * 60)
        let ratio = goal > 0 ? report.total / goal : 0
        let over = ratio > 1
        let color = over ? Color(red: 1, green: 0.32, blue: 0.42) : (ratio > 0.8 ? Color.orange : neon)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("יעד: \(formatDuration(goal))").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(over ? "חרגת ב-\(formatDuration(report.total - goal))"
                          : "נשארו \(formatDuration(goal - report.total))")
                    .font(.caption.weight(.bold)).foregroundStyle(color)
            }
            GeometryReader { geo in
                Capsule().fill(Color.white.opacity(0.08))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color).frame(width: geo.size.width * min(1, ratio))
                    }
            }
            .frame(height: 10)
        }
    }
}

struct WeekReportView: View {
    let report: WeekData

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "he")
        f.dateFormat = "EEEEE"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ממוצע יומי השבוע")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(formatDuration(report.average))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Chart(report.days) { day in
                BarMark(x: .value("יום", dayFormatter.string(from: day.id)),
                        y: .value("שעות", day.total / 3600))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(day.id)
                            ? AnyShapeStyle(LinearGradient(colors: [neon, accent], startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(accent.opacity(0.55))
                    )
                    .cornerRadius(6)
                if report.average > 0 {
                    RuleMark(y: .value("ממוצע", report.average / 3600))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.08))
                    AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v))ש") } }
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(card))
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
    }
}
