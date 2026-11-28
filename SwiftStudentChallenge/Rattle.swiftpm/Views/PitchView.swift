import SwiftUI

/// The play surface. The whole screen is one big input area so you can play
/// without looking: drag (or turn the device) to look around, tap to act.
struct PitchView: View {
    @EnvironmentObject private var game: GameModel
    let drill: Drill

    @State private var lastDragX: CGFloat = 0
    @State private var flash: Color = .clear
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                surface(size: geo.size)

                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 12)
                    Group {
                        if game.seeSound {
                            RadarView(markers: game.markers, drill: drill)
                        } else {
                            ListeningOrb(drill: drill, alignment: game.alignment, calls: game.calls)
                        }
                    }
                    .frame(maxWidth: 420, maxHeight: 420)
                    .padding(.horizontal, 24)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                    if game.seeSound && !game.soundCaption.isEmpty {
                        Label(game.soundCaption, systemImage: "captions.bubble")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.1), in: Capsule())
                            .padding(.top, 12)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    Spacer(minLength: 12)

                    Text(game.status)
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 600, minHeight: 70)
                        .padding(.horizontal, 24)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    hint
                        .padding(.bottom, 20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                RoundedRectangle(cornerRadius: 40)
                    .strokeBorder(flash, lineWidth: 14)
                    .blur(radius: 10)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: game.pulse) { _, pulse in
            guard let pulse else { return }
            flash = pulse.good ? Theme.good : Theme.bad
            withAnimation(.easeOut(duration: 0.9)) { flash = .clear }
        }
    }

    // MARK: Input surface

    private func surface(size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.translation.width - lastDragX
                        lastDragX = value.translation.width
                        if abs(value.translation.width) > abs(value.translation.height) {
                            game.turn(by: Double(dx) * 0.5)
                        }
                    }
                    .onEnded { value in
                        lastDragX = 0
                        let w = value.translation.width
                        let h = value.translation.height
                        if hypot(w, h) < 12 {
                            tap(x: value.location.x, width: size.width)
                        } else if drill == .voy, abs(w) > 40, abs(w) > abs(h) {
                            game.dodge(w < 0 ? -1 : 1)
                        } else if drill == .shoot, h < -60, abs(h) > abs(w) * 1.3 {
                            game.primaryAction()
                        }
                    }
            )
            // Hardware keyboard: ← → to turn or dodge, space or ↑ to act.
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(.leftArrow) {
                if drill == .voy { game.dodge(-1) } else { game.turn(by: -10) }
                return .handled
            }
            .onKeyPress(.rightArrow) {
                if drill == .voy { game.dodge(1) } else { game.turn(by: 10) }
                return .handled
            }
            .onKeyPress(.space) { game.primaryAction(); return .handled }
            .onKeyPress(.upArrow) { game.primaryAction(); return .handled }
            .onAppear { focused = true }
            // VoiceOver: swipe up/down turns you, double-tap acts, rotor dodges.
            .accessibilityElement()
            .accessibilityLabel(drill.surfaceLabel)
            .accessibilityValue(game.status)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: game.turn(by: 15)
                case .decrement: game.turn(by: -15)
                @unknown default: break
                }
            }
            .accessibilityAction { game.primaryAction() }
            .accessibilityActions {
                if drill == .voy {
                    Button("Dodge left") { game.dodge(-1) }
                    Button("Dodge right") { game.dodge(1) }
                }
            }
    }

    private func tap(x: CGFloat, width: CGFloat) {
        if drill == .voy {
            game.dodge(x < width / 2 ? -1 : 1)
        } else {
            game.primaryAction()
        }
    }

    // MARK: Chrome

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DRILL \(drill.number) · \(drill.title.uppercased())")
                    .font(.caption.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.color(for: drill))
                HStack(spacing: 6) {
                    ForEach(1...GameModel.rounds, id: \.self) { i in
                        Circle()
                            .fill(i <= game.round ? Theme.color(for: drill) : Color.white.opacity(0.2))
                            .frame(width: 9, height: 9)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Round \(game.round) of \(GameModel.rounds)")
            }
            Spacer()
            Toggle(isOn: $game.seeSound) {
                Image(systemName: game.seeSound ? "eye" : "eye.slash")
            }
            .toggleStyle(.button)
            .accessibilityLabel("See the sound")
            .accessibilityHint("Shows a map of where each sound is, with captions.")

            if game.motionAvailable && drill != .voy {
                Toggle(isOn: $game.turnWithDevice) {
                    Image(systemName: "gyroscope")
                }
                .toggleStyle(.button)
                .accessibilityLabel("Turn with device")
            }

            Button {
                game.skip()
            } label: {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Skip drill")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var hint: some View {
        let text: String
        switch drill {
        case .locate: text = "Turn or drag to look around · Tap to trap"
        case .voy: text = "Swipe or tap away from the voice"
        case .shoot: text = "Turn or drag to aim · Tap or swipe up to shoot"
        }
        return Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
    }
}

/// What you see with your "eyes closed": a dark, calm orb that glows brighter
/// the more squarely you face the sound — so the game also works by sight
/// alone for players who are deaf or hard of hearing.
struct ListeningOrb: View {
    let drill: Drill
    let alignment: Double
    let calls: Int

    @State private var callFlash = 0.0

    var body: some View {
        let color = Theme.color(for: drill)
        ZStack {
            SoundWaves(color: color, intensity: 0.25 + 0.75 * alignment)
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.15 + 0.75 * alignment), .clear],
                                     center: .center, startRadius: 4, endRadius: 170))
                .scaleEffect(0.6 + 0.4 * alignment)
            Circle()
                .strokeBorder(color.opacity(callFlash), lineWidth: 6)
                .scaleEffect(1.1 - 0.2 * callFlash)
            Image(systemName: "ear")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.35 + 0.5 * alignment))
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeOut(duration: 0.15), value: alignment)
        .onChange(of: calls) { _, _ in
            callFlash = 1
            withAnimation(.easeOut(duration: 0.6)) { callFlash = 0 }
        }
    }
}

/// Top-down view used by "See the sound". You're in the centre, always facing up.
struct RadarView: View {
    let markers: [Marker]
    let drill: Drill
    static let range = 11.0   // metres shown from centre to edge

    var body: some View {
        Canvas { context, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2 - 8

            for f in [1.0 / 3, 2.0 / 3, 1.0] {
                let rr = r * f
                context.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                               with: .color(.white.opacity(0.12)), lineWidth: 1)
            }

            // Your field of view.
            var cone = Path()
            cone.move(to: c)
            cone.addArc(center: c, radius: r, startAngle: .degrees(-90 - 15), endAngle: .degrees(-90 + 15), clockwise: false)
            cone.closeSubpath()
            context.fill(cone, with: .color(.white.opacity(0.08)))

            func point(_ bearing: Double, _ distance: Double) -> CGPoint {
                let a = bearing * .pi / 180
                let d = r * min(1, distance / Self.range)
                return CGPoint(x: c.x + sin(a) * d, y: c.y - cos(a) * d)
            }

            for m in markers {
                switch m.kind {
                case .goal:
                    var arc = Path()
                    let start = point(m.bearing - GameModel.goalHalfAngle, m.distance)
                    arc.move(to: start)
                    arc.addLine(to: point(m.bearing + GameModel.goalHalfAngle, m.distance))
                    context.stroke(arc, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                case .ball, .defender, .guide:
                    let p = point(m.bearing, m.distance)
                    let color: Color = m.kind == .ball ? Theme.ball : (m.kind == .defender ? Theme.defender : Theme.guide)
                    let size: CGFloat = m.kind == .ball ? 16 : 20
                    context.fill(Path(ellipseIn: CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size)),
                                 with: .color(color))
                    let label = m.kind == .ball ? "Ball" : (m.kind == .defender ? "Defender" : "Guide")
                    context.draw(Text(label).font(.caption2.weight(.bold)).foregroundColor(color),
                                 at: CGPoint(x: p.x, y: p.y + 18))
                }
            }

            context.fill(Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)), with: .color(.white))
            context.draw(Text("You").font(.caption2.weight(.bold)).foregroundColor(.white),
                         at: CGPoint(x: c.x, y: c.y + 20))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
