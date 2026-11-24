import DeviceActivity
import Foundation

/// Runs in the background (launched by iOS) when monitored intervals start/end
/// and when usage thresholds are reached. Keep it light: ~6MB memory limit.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = SharedStore.shared

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        switch activity {
        case .schedule:
            if ShieldController.reconcile(force: .schedule) == .schedule {
                Notifier.send(title: "🌙 Block time started",
                              body: "Your chosen apps are blocked now. Time to rest from the screen.",
                              id: "schedule.start")
            }
        case .daily:
            // A new day: yesterday's limit flag no longer applies.
            ShieldController.reconcile()
        default:
            // .session / .unlock are started by the app, which already applied state.
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        switch activity {
        case .schedule:
            ShieldController.reconcile(ignore: [.schedule])
            Notifier.send(title: "☀️ Block time ended",
                          body: "Your apps are open again. Use them wisely.",
                          id: "schedule.end")

        case .session:
            if let start = store.sessionStart, let end = store.sessionEnd {
                store.focusMinutesTotal += max(0, Int(end.timeIntervalSince(start) / 60))
            }
            store.sessionEnd = nil
            store.sessionStart = nil
            ShieldController.reconcile(ignore: [.session])
            Notifier.send(title: "🎉 Focus session complete",
                          body: "Well done! You made it to the end.",
                          id: "session.end")

        case .unlock:
            store.unlockUntil = nil
            if ShieldController.reconcile() != nil {
                Notifier.send(title: "⏳ Break is over",
                              body: "Your apps are blocked again. Back to real life.",
                              id: "unlock.end")
            }

        default:
            break
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        switch event {
        case .limitReached:
            store.limitReachedDay = DayKey.today
            store.markFailed()
            ShieldController.reconcile()
            Notifier.send(title: "⏰ Daily limit reached",
                          body: "You've used all \(store.dailyLimitMinutes) minutes for today. See you tomorrow!",
                          id: "limit.reached")

        case .limitWarning:
            Notifier.send(title: "⚠️ 5 minutes left",
                          body: "Your chosen apps will be blocked for today soon.",
                          id: "limit.warning")

        default:
            break
        }
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        if activity == .schedule {
            Notifier.send(title: "🌙 Block time starts in 10 minutes",
                          body: "Time to wrap up what you're doing.",
                          id: "schedule.warning")
        }
    }
}
