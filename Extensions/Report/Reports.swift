import DeviceActivity
import ManagedSettings
import SwiftUI

struct AppUsage: Identifiable {
    let id: String
    let name: String
    let token: ApplicationToken?
    let duration: TimeInterval
    let pickups: Int
}

struct TodayData {
    var total: TimeInterval = 0
    var pickups: Int = 0
    var apps: [AppUsage] = []
}

struct DayTotal: Identifiable {
    let id: Date
    let total: TimeInterval
}

struct WeekData {
    var days: [DayTotal] = []
    var average: TimeInterval {
        let nonEmpty = days.filter { $0.total > 0 }
        guard !nonEmpty.isEmpty else { return 0 }
        return nonEmpty.map(\.total).reduce(0, +) / Double(nonEmpty.count)
    }
}

// MARK: - Today

struct TodayReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .today
    let content: (TodayData) -> TodayReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TodayData {
        var result = TodayData()
        var byApp: [String: AppUsage] = [:]

        for await device in data {
            for await segment in device.activitySegments {
                result.total += segment.totalActivityDuration
                for await category in segment.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName
                            ?? app.application.bundleIdentifier ?? "אפליקציה"
                        let key = app.application.bundleIdentifier ?? name
                        let prev = byApp[key]
                        byApp[key] = AppUsage(id: key,
                                              name: name,
                                              token: app.application.token,
                                              duration: (prev?.duration ?? 0) + app.totalActivityDuration,
                                              pickups: (prev?.pickups ?? 0) + app.numberOfPickups)
                        result.pickups += app.numberOfPickups
                    }
                }
            }
        }
        result.apps = byApp.values.sorted { $0.duration > $1.duration }.prefix(8).map { $0 }
        return result
    }
}

// MARK: - Week

struct WeekReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .week
    let content: (WeekData) -> WeekReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> WeekData {
        var totals: [Date: TimeInterval] = [:]
        let cal = Calendar.current
        for await device in data {
            for await segment in device.activitySegments {
                let day = cal.startOfDay(for: segment.dateInterval.start)
                totals[day, default: 0] += segment.totalActivityDuration
            }
        }
        // Always show the last 7 days, even empty ones.
        let today = cal.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap { offset -> DayTotal? in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(id: d, total: totals[d] ?? 0)
        }
        return WeekData(days: days)
    }
}

func formatDuration(_ t: TimeInterval) -> String {
    let minutes = Int(t / 60)
    let h = minutes / 60, m = minutes % 60
    if h == 0 { return "\(m) דק׳" }
    return m == 0 ? "\(h) שע׳" : "\(h) שע׳ \(m) דק׳"
}
