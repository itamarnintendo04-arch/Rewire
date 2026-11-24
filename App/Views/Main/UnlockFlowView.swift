import SwiftUI

/// The "friction" flow: before unlocking, the user must wait and breathe.
struct UnlockFlowView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    enum Phase { case ask, breathe, choose }
    @State private var phase: Phase = .ask
    @State private var remaining = 15
    @State private var inhale = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 28) {
                switch phase {
                case .ask: ask
                case .breathe: breathe
                case .choose: choose
                }
            }
            .padding(24)
        }
        .onReceive(ticker) { _ in
            guard phase == .breathe else { return }
            if remaining > 0 {
                remaining -= 1
                if remaining % 4 == 0 { withAnimation(.easeInOut(duration: 4)) { inhale.toggle() } }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation { phase = .choose }
            }
        }
    }

    private var ask: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🤔").font(.system(size: 80))
            Text("את/ה באמת צריך/ה את זה עכשיו?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center).foregroundStyle(.white)
            Text(model.canUnlock
                 ? "נשארו לך \(model.unlocksLeft) שחרורים היום."
                 : unavailableReason)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            if model.canUnlock {
                Button("כן, אני צריך/ה כמה דקות") {
                    remaining = model.unlockWaitSeconds
                    withAnimation { phase = .breathe }
                    withAnimation(.easeInOut(duration: 4)) { inhale = true }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Button("לא, אני מוותר/ת 💪") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    private var unavailableReason: String {
        if model.strictMode { return "מצב קשוח פעיל – אין שחרורים. את/ה חזק/ה יותר מהדחף." }
        if model.activeReason == .session { return "סשן פוקוס פעיל – אי אפשר לשחרר באמצע." }
        if model.activeReason == nil { return "שום דבר לא חסום כרגע." }
        return "ניצלת את כל השחרורים להיום. נתראה מחר!"
    }

    private var breathe: some View {
        VStack(spacing: 34) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.25))
                    .frame(width: 260, height: 260)
                    .scaleEffect(inhale ? 1.0 : 0.55)
                    .blur(radius: 10)
                Circle().fill(Theme.gradient)
                    .frame(width: 160, height: 160)
                    .scaleEffect(inhale ? 1.0 : 0.6)
                Text("\(remaining)")
                    .font(.system(size: 48, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            Text(inhale ? "שאיפה…" : "נשיפה…")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("רגע של עצירה לפני שהדחף מחליט בשבילך")
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Button("התחרטתי, לא צריך") { dismiss() }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var choose: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("לכמה זמן?")
                .font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text("אחרי הזמן הזה הכל ננעל שוב אוטומטית.")
                .foregroundStyle(.white.opacity(0.6))
            ForEach([5, 10, 15], id: \.self) { m in
                Button("\(m) דקות") {
                    model.unlock(minutes: m)
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
            Button("בעצם, אני מוותר/ת 💪") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}
