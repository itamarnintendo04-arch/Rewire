import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var showPicker = false
    @State private var confirmReset = false

    var body: some View {
        Screen(title: "הגדרות") {
            section("אפליקציות חסומות") {
                SelectionSummary(selection: model.selection) { showPicker = true }
                    .disabled(model.strictMode && model.activeReason != nil)
                if model.strictMode && model.activeReason != nil {
                    Text("במצב קשוח אי אפשר לשנות את הרשימה בזמן חסימה.")
                        .font(.footnote).foregroundStyle(Theme.warning)
                }
            }

            section("יעד זמן מסך יומי") {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        MinutesDial(minutes: $model.goalMinutes, range: 15...600,
                                    color: AnyShapeStyle(Theme.neon))
                        if let r = model.quizResult {
                            Text("התחלת עם \(formatMinutes(r.currentMinutes)) ביום.")
                                .font(.footnote).foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
            }

            section("מגבלה יומית לאפליקציות חסומות") {
                Card { DailyLimitEditor() }
                    .disabled(model.strictMode && model.activeReason == .limit)
            }

            section("זמני חסימה") {
                Card { ScheduleEditor() }
            }

            section("שחרורים") {
                Card {
                    VStack(spacing: 16) {
                        Toggle(isOn: $model.strictMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("🔒 מצב קשוח").font(.headline).foregroundStyle(.white)
                                Text("בלי שחרורים ובלי סיום סשן מוקדם").font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .tint(Theme.danger)

                        if !model.strictMode {
                            Stepper(value: $model.maxUnlocksPerDay, in: 0...10) {
                                row("שחרורים ביום", "\(model.maxUnlocksPerDay)")
                            }
                            Stepper(value: $model.unlockWaitSeconds, in: 5...120, step: 5) {
                                row("זמן המתנה לפני שחרור", "\(model.unlockWaitSeconds) שנ׳")
                            }
                        }
                    }
                }
            }

            section("חשבון") {
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        row("זמן מסך", model.isAuthorized ? "מחובר ✓" : "לא מחובר")
                        if !model.isAuthorized {
                            Button("חבר/י מחדש") { Task { _ = await model.requestAuthorization() } }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                        Divider().overlay(Theme.stroke)
                        TextField("השם שלך", text: $model.userName)
                            .foregroundStyle(.white)
                        Divider().overlay(Theme.stroke)
                        Button("לעשות את השאלון מחדש") { confirmReset = true }
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            Text("Rewire 1.0 · הנתונים נשארים במכשיר")
                .font(.caption).foregroundStyle(.white.opacity(0.35))
                .padding(.top, 8)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)
        .onChange(of: model.dailyLimitMinutes) { _ in debounceApply() }
        .onChange(of: model.scheduleStart) { _ in debounceApply() }
        .onChange(of: model.scheduleEnd) { _ in debounceApply() }
        .confirmationDialog("לעשות את השאלון מחדש?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("כן, מההתחלה") { model.resetOnboarding() }
            Button("ביטול", role: .cancel) {}
        }
    }

    @State private var applyTask: Task<Void, Never>?

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
