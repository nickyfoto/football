import SwiftUI

enum Theme {
    static let night = Color(red: 0.03, green: 0.05, blue: 0.09)
    static let turf = Color(red: 0.05, green: 0.16, blue: 0.12)
    static let ball = Color(red: 1.0, green: 0.82, blue: 0.25)
    static let defender = Color(red: 1.0, green: 0.42, blue: 0.32)
    static let guide = Color(red: 0.35, green: 0.85, blue: 0.85)
    static let good = Color(red: 0.4, green: 0.95, blue: 0.55)
    static let bad = Color(red: 1.0, green: 0.4, blue: 0.4)

    static func color(for drill: Drill) -> Color {
        switch drill {
        case .locate: return ball
        case .voy: return defender
        case .shoot: return guide
        }
    }
}

struct RootView: View {
    @StateObject private var game = GameModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.night, Theme.turf.opacity(0.6), Theme.night],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            switch game.stage {
            case .welcome:
                WelcomeView().transition(.opacity)
            case .story:
                StoryView().transition(.opacity)
            case .intro(let drill):
                DrillIntroView(drill: drill).transition(.opacity)
            case .play(let drill):
                PitchView(drill: drill).transition(.opacity)
            case .finale:
                FinaleView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: game.stage)
        .environmentObject(game)
        .preferredColorScheme(.dark)
        .tint(Theme.ball)
    }
}

/// Big, high-contrast primary button used throughout.
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
            .foregroundStyle(.black)
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(Theme.ball, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
