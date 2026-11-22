import SwiftUI

/// Edit this! Judges respond to *your* reason for building the app.
/// Put one or two honest sentences here about why you made Rattle
/// (a person, a moment, a match you watched). Leave it `nil` to skip.
let personalNote: String? = nil

struct StoryView: View {
    @EnvironmentObject private var game: GameModel
    @State private var index = 0

    private var lines: [(symbol: String, text: String)] {
        var all: [(symbol: String, text: String)] = []
        if let personalNote { all.append((symbol: "heart", text: personalNote)) }
        all += [
            ("figure.soccer", "Blind football is five-a-side football for blind and partially sighted players. It has been part of every Paralympic Games since Athens 2004."),
            ("eyes.inverse", "Every outfield player wears an eyeshade, so no one can see — not even a little. The only sighted player is the goalkeeper."),
            ("speaker.wave.3", "So the game is played by sound: a ball that rattles, defenders who must shout “Voy!”, and a guide behind the goal calling out where to shoot."),
            ("headphones", "For the next three minutes, you'll train the same way. Put on headphones, close your eyes if you like, and listen.")
        ]
        return all
    }

    var body: some View {
        let line = lines[index]
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: line.symbol)
                .font(.system(size: 60))
                .foregroundStyle(Theme.ball)
                .accessibilityHidden(true)
                .id("symbol\(index)")
                .transition(.scale.combined(with: .opacity))
            Text(line.text)
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
                .padding(.horizontal, 28)
                .id("text\(index)")
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            HStack(spacing: 8) {
                ForEach(lines.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Theme.ball : Color.white.opacity(0.25))
                        .frame(width: i == index ? 22 : 8, height: 8)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            if index < lines.count - 1 {
                PrimaryButton(title: "Next") { advance() }
            } else {
                PrimaryButton(title: "Start training", symbol: "ear") { game.showIntro(.locate) }
            }
            Spacer().frame(height: 24)
        }
        .animation(.easeInOut(duration: 0.4), value: index)
        .onAppear { game.speak(lines[0].text) }
    }

    private func advance() {
        index += 1
        game.speak(lines[index].text)
    }
}
