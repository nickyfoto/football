import SwiftUI

/// Edit this! Judges respond to *your* reason for building the app.
/// One or two honest sentences — a person, a moment, a class you took.
/// Leave it `nil` to hide it.
let personalNote: String? = nil

struct WelcomeView: View {
    @EnvironmentObject private var model: CoachModel

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer().frame(height: 40)
                BeatingHeart(size: 96)
                VStack(spacing: 10) {
                    Text("HandsOn")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                    Text("Someone collapses in front of you.\nWould you know what to do?")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                if let personalNote {
                    Text(personalNote)
                        .font(.body.italic())
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label("When the heart stops, every minute without CPR lowers the chance of survival. Starting CPR right away can double or triple it.", systemImage: "clock.badge.exclamationmark")
                    Label("In three minutes, learn the steps — then practise with your own hands while your phone coaches you.", systemImage: "hand.raised")
                    Label("No account. No internet. Works with VoiceOver.", systemImage: "lock.shield")
                }
                .font(.callout)
                .padding(22)
                .frame(maxWidth: 560, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))

                PrimaryButton(title: "Start") { model.begin() }
                Text("A practice tool, not a certified course or medical device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}

struct SceneView: View {
    @EnvironmentObject private var model: CoachModel
    let index: Int

    var body: some View {
        let step = sceneSteps[index]
        VStack(spacing: 28) {
            HStack(spacing: 8) {
                ForEach(sceneSteps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? Theme.heart : Color.white.opacity(0.2))
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: 400)
            .padding(.top, 24)
            .accessibilityElement()
            .accessibilityLabel("Step \(index + 1) of \(sceneSteps.count)")

            Spacer()
            Image(systemName: step.symbol)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Theme.heart)
                .accessibilityHidden(true)
            Text(step.title)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            Text(step.body)
                .font(.title3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 540)
            if index == sceneSteps.count - 1 {
                Label("Practice only — nothing is dialled.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PrimaryButton(title: step.action, symbol: "checkmark") { model.advanceScene(from: index) }
            Spacer().frame(height: 30)
        }
        .padding(.horizontal, 24)
    }
}

struct HandsView: View {
    @EnvironmentObject private var model: CoachModel

    private let points: [(String, String)] = [
        ("hand.raised.fill", "Heel of one hand on the centre of the chest — the lower half of the breastbone."),
        ("hands.clap.fill", "Other hand on top, fingers interlocked."),
        ("arrow.down.to.line", "Arms straight, shoulders over your hands. Push straight down 5–6 cm."),
        ("metronome", "100–120 pushes a minute. Let the chest rise fully between pushes.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 24)
                Text("Hands on the chest")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                ChestDiagram()
                    .frame(width: 220, height: 220)
                    .accessibilityElement()
                    .accessibilityLabel("Diagram: hands stacked in the centre of the chest, between the nipples.")
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(points, id: \.1) { point in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: point.0)
                                .font(.title3)
                                .foregroundStyle(Theme.heart)
                                .frame(width: 32)
                                .accessibilityHidden(true)
                            Text(point.1)
                        }
                    }
                }
                .padding(22)
                .frame(maxWidth: 560, alignment: .leading)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
                PrimaryButton(title: "Let's practise", symbol: "hand.raised") { model.chooseMode() }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}

/// A simple torso outline with the hand position marked.
struct ChestDiagram: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            var torso = Path()
            torso.move(to: CGPoint(x: w * 0.2, y: h * 0.05))
            torso.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.05), control: CGPoint(x: w * 0.5, y: h * 0.18))
            torso.addLine(to: CGPoint(x: w * 0.92, y: h * 0.25))
            torso.addLine(to: CGPoint(x: w * 0.82, y: h * 0.95))
            torso.addLine(to: CGPoint(x: w * 0.18, y: h * 0.95))
            torso.addLine(to: CGPoint(x: w * 0.08, y: h * 0.25))
            torso.closeSubpath()
            context.stroke(torso, with: .color(.white.opacity(0.5)), lineWidth: 2)

            // Breastbone
            var sternum = Path()
            sternum.move(to: CGPoint(x: w * 0.5, y: h * 0.16))
            sternum.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))
            context.stroke(sternum, with: .color(.white.opacity(0.25)), style: StrokeStyle(lineWidth: 6, lineCap: .round))

            // Nipple line
            for x in [0.33, 0.67] {
                context.fill(Path(ellipseIn: CGRect(x: w * x - 3, y: h * 0.43 - 3, width: 6, height: 6)), with: .color(.white.opacity(0.4)))
            }

            // Hands
            let center = CGPoint(x: w * 0.5, y: h * 0.48)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 30, y: center.y - 24, width: 60, height: 48)), with: .color(Theme.heart.opacity(0.35)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 18, y: center.y - 14, width: 36, height: 28)), with: .color(Theme.heart))
            context.draw(Text("Push here").font(.caption.weight(.bold)).foregroundColor(.white),
                         at: CGPoint(x: center.x, y: center.y + 40))
        }
    }
}

struct ModeView: View {
    @EnvironmentObject private var model: CoachModel

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer().frame(height: 24)
                Text("How do you want to practise?")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                if model.motionAvailable {
                    ModeCard(
                        selected: model.inputMode == .motion,
                        symbol: "iphone.radiowaves.left.and.right",
                        title: "Phone on a cushion",
                        badge: "Measures rate and depth",
                        text: "Put a firm cushion on the floor or a table. Hold your phone flat in one palm, screen up, other hand on top. Push straight down into the cushion. You won't need to see the screen — the coach will talk you through it."
                    ) { model.inputMode = .motion }
                }
                ModeCard(
                    selected: model.inputMode == .tap,
                    symbol: "hand.tap",
                    title: "Tap the screen",
                    badge: "Measures rate",
                    text: "Tap anywhere on the screen to the beat, as if each tap were a push. Works on any device. A keyboard space bar works too."
                ) { model.inputMode = .tap }

                Toggle(isOn: $model.beatOn) {
                    Label("Beat guide (sound and vibration)", systemImage: "metronome")
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 6)

                PrimaryButton(title: "Start 30-second practice", symbol: "play.fill") { model.startPractice() }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ModeCard: View {
    let selected: Bool
    let symbol: String
    let title: String
    let badge: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: symbol)
                    .font(.title)
                    .foregroundStyle(Theme.heart)
                    .frame(width: 40)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title).font(.headline)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected ? Theme.heart : .secondary)
                            .accessibilityHidden(true)
                    }
                    Text(badge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.good)
                    Text(text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .frame(maxWidth: 560, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(selected ? Theme.heart : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
