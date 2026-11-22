import SwiftUI

struct DrillIntroView: View {
    @EnvironmentObject private var game: GameModel
    let drill: Drill

    var body: some View {
        let color = Theme.color(for: drill)
        ScrollView {
            VStack(spacing: 26) {
                Spacer().frame(height: 30)
                Text("DRILL \(drill.number) OF \(Drill.allCases.count)")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(color)
                Image(systemName: drill.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(drill.title)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                Text(drill.tagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(drill.steps) { step in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: step.symbol)
                                .font(.title3)
                                .foregroundStyle(color)
                                .frame(width: 32)
                                .accessibilityHidden(true)
                            Text(step.text)
                                .font(.body)
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: 560, alignment: .leading)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))

                PrimaryButton(title: "Start drill", symbol: "play.fill") { game.startDrill(drill) }
                Button("Skip this drill") { game.skipDrill(drill) }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}
