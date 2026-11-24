import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var showPicker = false
    @State private var confirmReset = false
    @State private var applyTask: Task<Void, Never>?

    var body: some View {
        Screen(title: "Settings") {
            section("Profile") {
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Your name", text: $model.userName)
                            .foregroundStyle(.white)
                        Divider().overlay(Theme.stroke)
                        Stepper(value: $model.userAge, in: 8...99) {
                            row("Age", "\(model.userAge)")
                        }
                    }
                }
            }

            section("Daily screen time goal") {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        MinutesDial(minutes: $model.goalMinutes, range: 15...600,
                                    color: AnyShapeStyle(Theme.neon))
                        if let r = model.quizResult {
                            Text("You started at \(formatMinutes(r.currentMinutes)) a day.")
                                .font(.footnote).foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
            }

            section("Blocked apps") {
                SelectionSummary(selection: model.selection) { showPicker = true }
                    .disabled(model.strictMode && model.activeReason != nil)
                if model.strictMode && model.activeReason != nil {
                    Text("In strict mode you can't change the list while blocking is active.")
                        .font(.footnote).foregroundStyle(Theme.warning)
                }
            }

            section("Daily limit for blocked apps") {
                Card { DailyLimitEditor() }
                    .disabled(model.strictMode && model.activeReason == .limit)
            }

            section("Scheduled block times") {
                Card { ScheduleEditor() }
            }

            section("Unlocks") {
                Card {
                    VStack(spacing: 16) {
                        Toggle(isOn: $model.strictMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("🔒 Strict mode").font(.headline).foregroundStyle(.white)
                                Text("No unlocks and no ending sessions early").font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .tint(Theme.danger)

                        if !model.strictMode {
                            Stepper(value: $model.maxUnlocksPerDay, in: 0...10) {
                                row("Unlocks per day", "\(model.maxUnlocksPerDay)")
                            }
                            Stepper(value: $model.unlockWaitSeconds, in: 5...120, step: 5) {
                                row("Wait before unlocking", "\(model.unlockWaitSeconds)s")
                            }
                        }
                    }
                }
            }

            section("Account") {
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        row("Screen Time", model.isAuthorized ? "Connected ✓" : "Not connected")
                        if !model.isAuthorized {
                            Button("Reconnect") { Task { _ = await model.requestAuthorization() } }
                                .buttonStyle(SecondaryButtonStyle())
                            if let reason = model.authFailureReason {
                                Text(reason).font(.footnote).foregroundStyle(Theme.warning)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Divider().overlay(Theme.stroke)
                        Button("Retake the quiz") { confirmReset = true }
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            Text("Rewire \(appVersion) · your data stays on your device")
                .font(.caption).foregroundStyle(.white.opacity(0.35))
                .padding(.top, 8)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)
        .onChange(of: model.dailyLimitMinutes) { _ in debounceApply() }
        .onChange(of: model.scheduleStart) { _ in debounceApply() }
        .onChange(of: model.scheduleEnd) { _ in debounceApply() }
        .confirmationDialog("Retake the quiz?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Yes, start over") { model.resetOnboarding() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func debounceApply() {
        applyTask?.cancel()
        applyTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            model.applyRules()
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.white.opacity(0.55))
            content()
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.white)
            Spacer()
            Text(value).foregroundStyle(.white.opacity(0.6))
        }
    }
}
