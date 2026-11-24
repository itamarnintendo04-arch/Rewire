import Foundation
import ManagedSettings
import FamilyControls

/// Computes whether apps should be shielded right now and applies it.
/// Called from the app and from the DeviceActivityMonitor extension, so the
/// result is always derived from the shared state instead of each caller
/// toggling shields independently.
enum ShieldController {
    static let store = ManagedSettingsStore(named: .rewire)

    static func desiredReason(force: BlockReason? = nil,
                              ignore: Set<BlockReason> = [],
                              now: Date = Date()) -> BlockReason? {
        let s = SharedStore.shared
        if let until = s.unlockUntil, until > now { return nil }

        if !ignore.contains(.session), let end = s.sessionEnd, end > now {
            return .session
        }
        if !ignore.contains(.limit), s.limitEnabled, s.limitReachedToday {
            return .limit
        }
        if !ignore.contains(.schedule), s.scheduleEnabled,
           force == .schedule || s.isInsideSchedule(now) {
            return .schedule
        }
        return nil
    }

    @discardableResult
    static func reconcile(force: BlockReason? = nil, ignore: Set<BlockReason> = []) -> BlockReason? {
        let reason = desiredReason(force: force, ignore: ignore)
        if let reason {
            apply(reason)
        } else {
            clear()
        }
        return reason
    }

    static func apply(_ reason: BlockReason) {
        let s = SharedStore.shared
        let selection = s.selection
        s.activeReason = reason

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    static func clear() {
        SharedStore.shared.activeReason = nil
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }
}
