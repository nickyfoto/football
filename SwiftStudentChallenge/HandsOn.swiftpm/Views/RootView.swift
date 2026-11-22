import SwiftUI

enum Theme {
    static let background = Color(red: 0.07, green: 0.06, blue: 0.08)
    static let heart = Color(red: 0.96, green: 0.28, blue: 0.32)
    static let good = Color(red: 0.36, green: 0.86, blue: 0.52)
    static let warn = Color(red: 1.0, green: 0.74, blue: 0.28)
    static let card = Color.white.opacity(0.07)

    /// Green inside the target range, amber when slightly out, red when far out.
    static func color(for value: Double?, in range: ClosedRange<Double>, tolerance: Double) -> Color {
        guard let value else { return .secondary }
        if range.contains(value) { return good }
        let distance = value < range.lowerBound ? range.lowerBound - value : value - range.upperBound
        return distance <= tolerance ? warn : heart
    }
}

struct RootView: View {
    @StateObject private var model = CoachModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch model.stage {
            case .welcome: WelcomeView().transition(.opacity)
            case .scene(let i): SceneView(index: i).id(i).transition(.opacity)
            case .hands: HandsView().transition(.opacity)
            case .mode: ModeView().transition(.opacity)
            case .practice: PracticeView().transition(.opacity)
            case .results: ResultsView().transition(.opacity)
            case .finale: FinaleView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: model.stage)
        .environmentObject(model)
        .preferredColorScheme(.dark)
        .tint(Theme.heart)
    }
}

struct PrimaryButton: View {
    let title: String
    var symbol: String = "arrow.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                Image(systemName: symbol)
            }
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(Theme.heart, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A beating heart that follows the 110 bpm guideline tempo.
struct BeatingHeart: View {
    var size: CGFloat = 90
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let beat = 60 / Guideline.beatsPerMinute
            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: beat) / beat
            let pulse = reduceMotion ? 0 : max(0, 1 - phase * 4)
            Image(systemName: "heart.fill")
                .font(.system(size: size))
                .foregroundStyle(Theme.heart)
                .scaleEffect(1 + 0.12 * pulse)
                .shadow(color: Theme.heart.opacity(0.6 * pulse), radius: 24)
        }
        .accessibilityHidden(true)
    }
}
