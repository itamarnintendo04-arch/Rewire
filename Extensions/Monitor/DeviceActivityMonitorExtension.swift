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
                Notifier.send(title: "🌙 זמן החסימה התחיל",
                              body: "האפליקציות שבחרת חסומות עכשיו. זמן לנוח מהמסך.",
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
            Notifier.send(title: "☀️ זמן החסימה הסתיים",
                          body: "האפליקציות פתוחות שוב. תשתמש/י בהן בחוכמה.",
                          id: "schedule.end")

        case .session:
            if let start = store.sessionStart, let end = store.sessionEnd {
                store.focusMinutesTotal += max(0, Int(end.timeIntervalSince(start) / 60))
            }
            store.sessionEnd = nil
            store.sessionStart = nil
            ShieldController.reconcile(ignore: [.session])
            Notifier.send(title: "🎉 סשן הפוקוס הסתיים",
                          body: "כל הכבוד! החזקת מעמד עד הסוף.",
                          id: "session.end")

        case .unlock:
            store.unlockUntil = nil
            if ShieldController.reconcile() != nil {
                Notifier.send(title: "⏳ ההפסקה נגמרה",
                              body: "האפליקציות חסומות שוב. חזרה לחיים האמיתיים.",
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
            Notifier.send(title: "⏰ הגעת למגבלה היומית",
                          body: "ניצלת את כל \(store.dailyLimitMinutes) הדקות של היום. נתראה מחר!",
                          id: "limit.reached")

        case .limitWarning:
            Notifier.send(title: "⚠️ נשארו לך 5 דקות",
                          body: "עוד מעט האפליקציות שבחרת ייחסמו להיום.",
                          id: "limit.warning")

        default:
            break
        }
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        if activity == .schedule {
            Notifier.send(title: "🌙 עוד 10 דקות מתחיל זמן החסימה",
                          body: "זה הזמן לסגור את מה שאת/ה עושה.",
                          id: "schedule.warning")
        }
    }
}
