import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            SoundWaves(color: Theme.ball)
                .frame(width: 220, height: 220)
                .overlay {
                    Image(systemName: "soccerball")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(Theme.ball)
                }
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Rattle")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                Text("Football you play with your ears.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Label("Best with headphones — sound is in 3D.", systemImage: "headphones")
                Label("Playable with VoiceOver, a keyboard, or by touch alone.", systemImage: "accessibility")
                Label("About three minutes.", systemImage: "clock")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)

            Spacer()
            PrimaryButton(title: "Kick off") { game.begin() }
            Spacer().frame(height: 24)
        }
        .padding()
    }
}

/// Expanding rings, like sound travelling outward from the ball.
struct SoundWaves: View {
    let color: Color
    var intensity: Double = 1

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2
                for i in 0..<4 {
                    let phase = (t * 0.45 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
                    let radius = maxRadius * (0.3 + 0.7 * phase)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    context.stroke(Path(ellipseIn: rect),
                                   with: .color(color.opacity((1 - phase) * 0.7 * intensity)),
                                   lineWidth: 2.5)
                }
            }
        }
    }
}
