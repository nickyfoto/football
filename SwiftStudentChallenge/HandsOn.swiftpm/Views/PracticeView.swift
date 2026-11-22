import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var model: CoachModel
    @State private var pressed = false
    @State private var squash = 0.0
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            if model.inputMode == .tap { tapPad }

            VStack(spacing: 18) {
                header
                Spacer(minLength: 0)
                compressionRing
                    .frame(width: 250, height: 250)
                    .allowsHitTesting(false)
                Text(model.prompt.isEmpty ? " " : model.prompt)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 44)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                gauges
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
                if model.inputMode == .tap {
                    Text("Tap anywhere to the beat")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 24)

            if let n = model.countdown {
                Text("\(n)")
                    .font(.system(size: 140, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.heart)
                    .transition(.scale.combined(with: .opacity))
                    .id(n)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.countdown)
        .onChange(of: model.compressions.count) { _, _ in
            squash = 1
            withAnimation(.easeOut(duration: 0.35)) { squash = 0 }
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PRACTICE")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.heart)
                Text("\(Int(max(0, CoachModel.practiceSeconds - model.elapsed).rounded(.up))) s left")
                    .font(.headline.monospacedDigit())
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Toggle(isOn: $model.beatOn) {
                Image(systemName: model.beatOn ? "metronome.fill" : "metronome")
            }
            .toggleStyle(.button)
            .accessibilityLabel("Beat guide")
            Button("Stop") { model.stopPractice() }
                .buttonStyle(.bordered)
        }
        .padding(.top, 16)
    }

    private var compressionRing: some View {
        let progress = min(1, model.elapsed / CoachModel.practiceSeconds)
        return ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.heart, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.heart)
                    .scaleEffect(1 + 0.25 * squash)
                Text("\(model.compressions.count)")
                    .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                Text("compressions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(model.compressions.count) compressions")
    }

    private var gauges: some View {
        HStack(spacing: 14) {
            Meter(title: "Rate", unit: "/min",
                  value: model.currentRate, range: 60...160, target: Guideline.rate, tolerance: 8,
                  format: "%.0f")
            if model.inputMode == .motion {
                Meter(title: "Depth", unit: "cm",
                      value: model.currentDepth, range: 2...8, target: Guideline.depth, tolerance: 0.6,
                      format: "%.1f")
            }
        }
        .frame(maxWidth: 520)
    }

    /// Full-screen tap target for tap mode. Registers on touch-down for a
    /// tight rhythm. VoiceOver users get direct touch so taps go straight through.
    private var tapPad: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            model.tapCompression()
                        }
                    }
                    .onEnded { _ in pressed = false }
            )
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(.space) { model.tapCompression(); return .handled }
            .onAppear { focused = true }
            .accessibilityElement()
            .accessibilityLabel("Compression pad")
            .accessibilityHint("Tap to the beat. Each tap counts as one push.")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

/// A horizontal meter with the guideline range shaded.
private struct Meter: View {
    let title: String
    let unit: String
    let value: Double?
    let range: ClosedRange<Double>
    let target: ClosedRange<Double>
    let tolerance: Double
    let format: String

    var body: some View {
        let color = Theme.color(for: value, in: target, tolerance: tolerance)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(value.map { String(format: format, $0) } ?? "–")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let span = range.upperBound - range.lowerBound
                let x: (Double) -> CGFloat = { CGFloat((min(max($0, range.lowerBound), range.upperBound) - range.lowerBound) / span) * w }
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Rectangle()
                        .fill(Theme.good.opacity(0.35))
                        .frame(width: x(target.upperBound) - x(target.lowerBound))
                        .offset(x: x(target.lowerBound))
                    if let value {
                        Circle()
                            .fill(color)
                            .frame(width: 18, height: 18)
                            .offset(x: x(value) - 9)
                            .animation(.easeOut(duration: 0.2), value: value)
                    }
                }
            }
            .frame(height: 18)
            Text("Target \(String(format: format, target.lowerBound))–\(String(format: format, target.upperBound)) \(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value.map { "\(String(format: format, $0)) \(unit)" } ?? "Not measured yet")
    }
}
