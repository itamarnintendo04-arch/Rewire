import SwiftUI
import FamilyControls

struct FocusView: View {
    @EnvironmentObject var model: AppModel
    @State private var minutes = 30
    @State private var now = Date()
    @State private var confirmEnd = false
    @State private var showPicker = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let presets = [15, 25, 45, 60, 90, 120, 180, 240]

    var body: some View {
        Screen(title: "Focus session") {
            if let end = model.sessionEnd, end > now {
                activeSession(end: end)
            } else {
                setup
            }
        }
        .onReceive(ticker) { t in
            now = t
            if let end = model.sessionEnd, end <= t { model.refresh() }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)
        .alert("End the session early?", isPresented: $confirmEnd) {
            Button("Keep focusing", role: .cancel) {}
            Button("End", role: .destructive) { model.endSessionEarly() }
        } message: {
            Text("You're almost there. Are you sure?")
        }
    }

    private var setup: some View {
        VStack(spacing: 22) {
            Card {
                VStack(spacing: 18) {
                    Text("Block all your chosen apps for:")
                        .font(.headline).foregroundStyle(.white)
                    Text(formatMinutes(minutes))
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gradient)
                    Slider(value: Binding(get: { Double(minutes) }, set: { minutes = Int($0) }),
                           in: 5...480, step: 5)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(presets, id: \.self) { m in
                            Button { hapticTap(); minutes = m } label: {
                                Text(formatMinutes(m)).font(.caption.weight(.bold))
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(Capsule().fill(minutes == m ? Theme.accent.opacity(0.35) : Theme.card))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            SelectionSummary(selection: model.selection) { showPicker = true }

            if model.strictMode {
                Label("Strict mode is on: sessions can't be ended early", systemImage: "lock.trianglebadge.exclamationmark.fill")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Theme.warning)
            }

            Button {
                hapticTap(.heavy)
                model.startSession(minutes: minutes)
            } label: {
                Label("Start focus", systemImage: "lock.fill")
            }
            .buttonStyle(PrimaryButtonStyle(enabled: model.selectionCount > 0))
            .disabled(model.selectionCount == 0)
        }
    }

    private func activeSession(end: Date) -> some View {
        let total = max(1, end.timeIntervalSince(SharedStore.shared.sessionStart ?? end.addingTimeInterval(-3600)))
        let remaining = max(0, end.timeIntervalSince(now))
        return VStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 18)
                Circle().trim(from: 0, to: remaining / total)
                    .stroke(Theme.gradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)
                VStack(spacing: 6) {
                    Text(clock(remaining))
                        .font(.system(size: 50, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text("remaining").foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(width: 270, height: 270)
            .padding(.top, 20)

            Text("🎯 Your apps are blocked. Time to do something real.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            if model.canEndSessionEarly {
                Button("End early") { confirmEnd = true }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t), h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
    }
}
