import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let today = Self("today")
    static let week = Self("week")
}

/// Screen Time data can only be read and rendered inside this sandboxed
/// extension; the app embeds it with `DeviceActivityReport(...)`.
@main
struct RewireReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TodayReport { TodayReportView(report: $0) }
        WeekReport { WeekReportView(report: $0) }
    }
}
