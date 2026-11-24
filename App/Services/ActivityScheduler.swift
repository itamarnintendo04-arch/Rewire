import Foundation
import DeviceActivity
import FamilyControls

/// Registers the DeviceActivity schedules that wake the monitor extension.
enum ActivityScheduler {
    private static let center = DeviceActivityCenter()
    private static let store = SharedStore.shared

    /// Re-register everything from the current settings.
    static func refreshAll() {
        refreshDailyLimit()
        refreshSchedule()
        ShieldController.reconcile()
    }

    // MARK: Daily limit

    static func refreshDailyLimit() {
        center.stopMonitoring([.daily])
        guard store.limitEnabled, store.hasSelection else { return }

        let sel = store.selection
        let limit = store.dailyLimitMinutes
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .limitReached: DeviceActivityEvent(
                applications: sel.applicationTokens,
                categories: sel.categoryTokens,
                webDomains: sel.webDomainTokens,
                threshold: DateComponents(hour: limit / 60, minute: limit % 60)
            )
        ]
        if limit > 10 {
            let warn = limit - 5
            events[.limitWarning] = DeviceActivityEvent(
                applications: sel.applicationTokens,
                categories: sel.categoryTokens,
                webDomains: sel.webDomainTokens,
                threshold: DateComponents(hour: warn / 60, minute: warn % 60)
            )
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        do {
            try center.startMonitoring(.daily, during: schedule, events: events)
        } catch {
            print("Daily monitoring failed: \(error)")
        }
    }

    // MARK: Repeating schedule (e.g. bedtime)

    static func refreshSchedule() {
        center.stopMonitoring([.schedule])
        guard store.scheduleEnabled, store.scheduleStartMinutes != store.scheduleEndMinutes else { return }

        let s = store.scheduleStartMinutes, e = store.scheduleEndMinutes
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: s / 60, minute: s % 60),
            intervalEnd: DateComponents(hour: e / 60, minute: e % 60),
            repeats: true,
            warningTime: DateComponents(minute: 10)
        )
        do {
            try center.startMonitoring(.schedule, during: schedule)
        } catch {
            print("Schedule monitoring failed: \(error)")
        }
    }

    // MARK: One-shot intervals (focus session / temporary unlock)

    /// DeviceActivity requires intervals of at least 15 minutes, so for short
    /// windows we start the interval in the past and only rely on `intervalDidEnd`.
    static func scheduleOneShot(_ name: DeviceActivityName, until end: Date) throws {
        center.stopMonitoring([name])
        let now = Date()
        let start = min(now, end.addingTimeInterval(-16 * 60))
        let cal = Calendar.current
        let comps: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents(comps, from: start),
            intervalEnd: cal.dateComponents(comps, from: end),
            repeats: false
        )
        try center.startMonitoring(name, during: schedule)
    }

    static func stop(_ name: DeviceActivityName) {
        center.stopMonitoring([name])
    }
}
