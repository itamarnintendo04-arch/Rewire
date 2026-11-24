# Rewire – Screen Time control for iOS

A full SwiftUI screen-time app built on Apple's Screen Time APIs:
**FamilyControls**, **ManagedSettings** and **DeviceActivity**.

[![Build & Release](https://github.com/itamarnintendo04-arch/rewire/actions/workflows/build.yml/badge.svg)](https://github.com/itamarnintendo04-arch/rewire/actions/workflows/build.yml)

## Features

| Feature | Where |
|---|---|
| Profile: name and exact age | `ProfileView` in `App/Views/Onboarding/IntroViews.swift` |
| Onboarding quiz with a Brain Rot score | `App/Models/Quiz.swift`, `IntroViews.swift` |
| Current daily screen time and goal, set with sliders and live feedback | `App/Views/Onboarding/ScreenTimeInputViews.swift` |
| "Calculating…" screen, score vs. average, years-of-life-on-phone projection | `App/Views/Onboarding/ResultViews.swift` |
| Connect to Apple Screen Time (`AuthorizationCenter`) | `PermissionView` in `SetupViews.swift` |
| Pick apps, categories and websites to block (`FamilyActivityPicker`) | `SelectAppsView`, `SelectionSummary` |
| Daily limit: auto-block when time runs out, with a warning 5 min before | `ActivityScheduler.refreshDailyLimit` → `Extensions/Monitor` |
| Scheduled block times (night, school, work) | `ActivityScheduler.refreshSchedule` |
| Focus sessions ("block now" with a timer) | `FocusView` |
| Custom block screen with quotes and a blocked-attempts counter | `Extensions/ShieldConfiguration` |
| Block screen buttons: close, or request an unlock | `Extensions/ShieldAction` |
| Unlock with friction: breathe and wait, limited unlocks per day, auto re-lock | `UnlockFlowView` |
| Strict mode: no unlocks, no ending sessions early | `SettingsView` |
| Reports: today's total, per-app usage, pickups, goal progress, weekly chart | `Extensions/Report` |
| Streaks, best streak, total focus minutes | `SharedStore` |
| Hold-to-commit pledge | `CommitmentView` |

## Download a build

Every push to `main` builds the app on GitHub Actions. Every `v*` tag publishes a
**GitHub Release** with `Rewire.ipa`.

The `.ipa` is **unsigned**, with the entitlements embedded. To install it, re-sign it with your
own Apple ID or developer certificate, for example with Sideloadly, AltStore or Xcode.
Screen Time blocking needs the **Family Controls** capability on that account, and a real
iPhone running iOS 16 or later.

## Build it yourself

You need a Mac with Xcode 15 or later and a real iPhone. The Screen Time APIs do not work in the
Simulator.

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Generate the project and open it:
   ```bash
   xcodegen generate && open Rewire.xcodeproj
   ```
3. In `project.yml`, replace these with your own values:
   - `DEVELOPMENT_TEAM`: your Team ID.
   - `com.example.rewire`: your bundle ID prefix, in all 5 targets.
   - `group.com.example.rewire`: your App Group. It also appears in `Shared/SharedConstants.swift`
     and `Extensions/Report/ReportViews.swift`.
4. In the Apple Developer portal:
   - Create the App Group and assign it to the app and all 4 extensions.
   - Enable the **Family Controls** capability for every App ID.
5. Run on your device. The development Family Controls entitlement works without special approval.

### Before shipping to the App Store
Request the **Family Controls (Distribution)** entitlement from Apple for the app and each of the 4
extensions: https://developer.apple.com/contact/request/family-controls-distribution

## Architecture

```
App (SwiftUI)
 ├─ AppModel ── SharedStore (App Group UserDefaults) ◄── shared with all extensions
 ├─ ActivityScheduler ── DeviceActivityCenter.startMonitoring(...)
 └─ ShieldController ── ManagedSettingsStore("rewire")

Extensions
 ├─ Monitor          ← woken by iOS: interval start/end, usage thresholds
 ├─ ShieldConfig     ← draws the block screen
 ├─ ShieldAction     ← handles taps on the block screen buttons
 └─ Report           ← reads and renders Screen Time data (sandboxed)
```

- **`ShieldController.reconcile()`** works out on every call whether apps should be blocked, and why.
  The priority order is: an active unlock, then a focus session, then the daily limit, then the
  schedule. This keeps the app and the extensions from fighting each other.
- **Intervals shorter than 15 minutes.** DeviceActivity requires at least 15 minutes, so the interval
  start is set in the past and only `intervalDidEnd` is used as the timer. See `scheduleOneShot`.
- **Unlocking from the block screen.** An extension can't open its host app, so it posts a
  notification. Tapping it opens the unlock flow.

## Troubleshooting: "it doesn't ask for Screen Time access"

iOS shows the Screen Time permission dialog only when the installed app is signed with the
**`com.apple.developer.family-controls`** entitlement. If the entitlement is missing, iOS rejects the
request instantly and shows no dialog. The app now detects this and tells you why on the
permission screen.

- **AltStore, SideStore, or Sideloadly with a free Apple ID:** a free account can't grant this
  entitlement, so blocking will never work this way.
- **Paid developer account:** enable the *Family Controls* capability on the App ID of the app and of
  each extension, then re-sign. Building from Xcode with your team selected does this for you.
- **Other causes:** a child account in Family Sharing, Screen Time restricted by a parent or MDM
  profile, or no device passcode set. The permission screen shows the exact reason.

## Apple limitations to know
- Usage data is only available inside the Report extension and cannot be sent out of it.
- The Monitor extension has a memory limit of about 6 MB, so it is kept lightweight.
- `eventDidReachThreshold` can arrive a minute or two late. This is iOS behavior.
