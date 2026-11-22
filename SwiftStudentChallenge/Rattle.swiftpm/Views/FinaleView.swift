import SwiftUI

struct FinaleView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer().frame(height: 30)
                Text("FULL TIME")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.ball)
                Text("You played blind.")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                HStack(spacing: 14) {
                    stat(value: game.trapped, label: "Balls trapped", color: Theme.ball,
                         detail: "in \(game.trapTries) \(game.trapTries == 1 ? "try" : "tries")")
                    stat(value: game.dodged, label: "Defenders beaten", color: Theme.defender, detail: "of \(GameModel.rounds)")
                    stat(value: game.goals, label: "Goals", color: Theme.guide, detail: "of \(GameModel.rounds)")
                }
                .frame(maxWidth: 600)

                VStack(alignment: .leading, spacing: 14) {
                    fact("figure.run", "Elite blind-football players do all of this at full sprint, with three other outfield players and a goalkeeper around them.")
                    fact("speaker.slash", "Spectators stay silent during play so players can hear the ball — then cheer when a goal goes in.")
                    fact("person.2", "Want to try the real thing? Many national blind-sport associations run open sessions for blind and sighted players.")
                }
                .padding(22)
                .frame(maxWidth: 600, alignment: .leading)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))

                PrimaryButton(title: "Play again", symbol: "arrow.counterclockwise") { game.playAgain() }
                Button("Back to start") { game.goHome() }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func stat(value: Int, label: String, color: Color, detail: String) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    private func fact(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.ball)
                .frame(width: 32)
                .accessibilityHidden(true)
            Text(text)
        }
    }
}
