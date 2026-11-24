import SwiftUI
import FamilyControls

// MARK: - Screen Time permission

struct PermissionView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void
    @State private var requesting = false
    @State private var denied = false

    var body: some View {
        OnboardingPage {
            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32).fill(Theme.card).frame(width: 130, height: 130)
                    Image(systemName: "hourglass.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.gradient)
                }
                .padding(.top, 20)

                StepHeader(title: "Connect to Screen Time",
                           subtitle: "Rewire uses Apple's Screen Time to block apps and measure your usage.")

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        privacyRow("lock.fill", "Your data never leaves your device")
                        privacyRow("eye.slash.fill", "We can't see what you do inside apps")
                        privacyRow("apple.logo", "Secured by Apple with Face ID")
                    }
                }

                if denied {
                    Text("Permission was denied. You can allow it in Settings → Screen Time, or try again.")
                        .font(.footnote).foregroundStyle(Theme.warning)
                        .multilineTextAlignment(.center)
                }
            }
        } footer: {
            VStack(spacing: 10) {
                Button {
                    Task {
                        requesting = true
                        let ok = await model.requestAuthorization()
                        requesting = false
                        if ok { onNext() } else { denied = true }
                    }
                } label: {
                    HStack {
                        if requesting { ProgressView().tint(.white) }
                        Text(model.isAuthorized ? "Connected ✓ Continue" : "Connect Screen Time")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(requesting)

                Text("In the next dialog tap \"Continue\" and confirm with your passcode or Face ID")
                    .font(.footnote).foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { if model.isAuthorized { denied = false } }
    }

    private func privacyRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.neon).frame(width: 24)
            Text(text).font(.subheadline).foregroundStyle(.white.opacity(0.85))
        }
    }
}

// MARK: - Choose apps to block

struct SelectAppsView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void
    @State private var showPicker = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: "Which apps should we block?",
                           subtitle: "Choose apps, whole categories or websites. You can change this anytime.")

                if let apps = model.quizResult?.topApps, !apps.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Based on your quiz, consider:").font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(apps.joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }

                SelectionSummary(selection: model.selection) { showPicker = true }
            }
        } footer: {
            VStack(spacing: 10) {
                if model.selectionCount == 0 {
                    Button("Choose apps") { showPicker = true }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Continue", action: onNext).buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)
    }
}

/// Shows the chosen apps/categories/sites using Apple's opaque token labels.
struct SelectionSummary: View {
    var selection: FamilyActivitySelection
    var onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "square.grid.2x2.fill").foregroundStyle(Theme.accent)
                        Text(title).font(.headline).foregroundStyle(.white)
                        Spacer()
                        Text(isEmpty ? "Choose" : "Edit")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    }
                    if !isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                            ForEach(Array(selection.applicationTokens.prefix(18)), id: \.self) { token in
                                Label(token).labelStyle(.iconOnly).frame(width: 40, height: 40)
                            }
                            ForEach(Array(selection.categoryTokens.prefix(12)), id: \.self) { token in
                                Label(token).labelStyle(.iconOnly).frame(width: 40, height: 40)
                            }
                        }
                        if !selection.webDomainTokens.isEmpty {
                            Text("+ \(selection.webDomainTokens.count) websites")
                                .font(.caption).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var isEmpty: Bool {
        selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty && selection.webDomainTokens.isEmpty
    }

    private var title: String {
        if isEmpty { return "No apps selected yet" }
        var parts: [String] = []
        if !selection.applicationTokens.isEmpty { parts.append("\(selection.applicationTokens.count) apps") }
        if !selection.categoryTokens.isEmpty { parts.append("\(selection.categoryTokens.count) categories") }
        if !selection.webDomainTokens.isEmpty { parts.append("\(selection.webDomainTokens.count) sites") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Daily limit

struct DailyLimitSetupView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: "Daily limit",
                           subtitle: "How much time per day do you allow yourself in these apps? After that they lock until tomorrow.")
                DailyLimitEditor()
            }
        } footer: {
            Button("Continue") { model.applyRules(); onNext() }.buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct DailyLimitEditor: View {
    @EnvironmentObject var model: AppModel
    private let presets = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 20) {
            Toggle(isOn: $model.limitEnabled) {
                Text("Enable daily limit").font(.headline).foregroundStyle(.white)
            }
            .tint(Theme.accent)

            if model.limitEnabled {
                Text(formatMinutes(model.dailyLimitMinutes))
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gradient)
                    .frame(maxWidth: .infinity)

                Slider(value: Binding(get: { Double(model.dailyLimitMinutes) },
                                      set: { model.dailyLimitMinutes = Int($0) }),
                       in: 5...240, step: 5)
                    .tint(Theme.accent)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(presets, id: \.self) { m in
                        Button {
                            hapticTap()
                            model.dailyLimitMinutes = m
                        } label: {
                            Text(formatMinutes(m))
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .fill(model.dailyLimitMinutes == m ? Theme.accent.opacity(0.3) : Theme.card))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(model.dailyLimitMinutes == m ? Theme.accent : Theme.stroke))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Your overall goal: \(formatMinutes(model.goalMinutes)) a day. We recommend giving distracting apps at most half of it.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

// MARK: - Schedule

struct ScheduleSetupView: View {
    @EnvironmentObject var model: AppModel
    var onNext: () -> Void

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                StepHeader(title: "Scheduled block times",
                           subtitle: "For example, phone-free nights: your apps block automatically every day during these hours.")
                ScheduleEditor()
            }
        } footer: {
            Button("Continue") { model.applyRules(); onNext() }.buttonStyle(PrimaryButtonStyle())
        }
    }
}

struct ScheduleEditor: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 18) {
            Toggle(isOn: $model.scheduleEnabled) {
                Text("🌙 Enable scheduled blocking").font(.headline).foregroundStyle(.white)
            }
            .tint(Theme.accent)

            if model.scheduleEnabled {
                Card {
                    VStack(spacing: 14) {
                        DatePicker("Starts", selection: $model.scheduleStart, displayedComponents: .hourAndMinute)
                        Divider().overlay(Theme.stroke)
                        DatePicker("Ends", selection: $model.scheduleEnd, displayedComponents: .hourAndMinute)
                    }
                    .foregroundStyle(.white)
                }
                HStack(spacing: 10) {
                    preset("Night", 22 * 60, 7 * 60)
                    preset("School", 8 * 60, 14 * 60)
                    preset("Work", 9 * 60, 17 * 60)
                }
            }
        }
    }

    private func preset(_ title: String, _ start: Int, _ end: Int) -> some View {
        Button {
            hapticTap()
            model.scheduleStart = .fromMinutes(start)
            model.scheduleEnd = .fromMinutes(end)
        } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(Capsule().fill(Theme.card))
                .overlay(Capsule().stroke(Theme.stroke))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Commitment (hold to commit)

struct CommitmentView: View {
    @EnvironmentObject var model: AppModel
    var onDone: () -> Void
    @State private var progress: CGFloat = 0
    @State private var holding = false
    @State private var done = false
    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        OnboardingPage {
            VStack(spacing: 26) {
                StepHeader(title: "Your commitment",
                           subtitle: "Change starts with a decision. Press and hold to commit.")

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I, \(model.userName), commit to:").font(.headline).foregroundStyle(.white)
                        pledge("Use my phone with intention, not out of habit")
                        pledge("Reach my goal of \(formatMinutes(model.goalMinutes)) of screen time a day")
                        if model.limitEnabled {
                            pledge("No more than \(formatMinutes(model.dailyLimitMinutes)) a day in the apps I chose")
                        }
                        if model.scheduleEnabled {
                            pledge("Respect my scheduled block times")
                        }
                        pledge("Take back my time, focus and sleep")
                    }
                }

                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 10)
                    Circle().trim(from: 0, to: progress)
                        .stroke(Theme.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: done ? "checkmark" : "hand.point.up.left.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(done ? Theme.neon : .white)
                        .scaleEffect(holding ? 0.9 : 1)
                }
                .frame(width: 150, height: 150)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !holding { holding = true; hapticTap(.medium) } }
                        .onEnded { _ in holding = false }
                )
                Text(done ? "Awesome! Let's go 🚀" : "Hold for 3 seconds")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.7))
            }
        } footer: {
            EmptyView()
        }
        .onReceive(timer) { _ in
            guard !done else { return }
            if holding {
                progress = min(1, progress + 0.0067)
                if Int(progress * 100) % 10 == 0 { hapticTap(.light) }
                if progress >= 1 {
                    done = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: onDone)
                }
            } else if progress > 0 {
                progress = max(0, progress - 0.02)
            }
        }
    }

    private func pledge(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.neon)
            Text(text).foregroundStyle(.white.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
        }
    }
}
