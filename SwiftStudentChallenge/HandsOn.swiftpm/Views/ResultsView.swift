import SwiftUI
import Charts

struct ResultsView: View {
    @EnvironmentObject private var model: CoachModel

    var body: some View {
        let r = model.results
        ScrollView {
            VStack(spacing: 22) {
                Spacer().frame(height: 24)
                ZStack {
                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: Double(r.score) / 100)
                        .stroke(r.score >= 80 ? Theme.good : (r.score >= 60 ? Theme.warn : Theme.heart),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(r.score)")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                        Text("out of 100").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 170, height: 170)
                .accessibilityElement()
                .accessibilityLabel("Score \(r.score) out of 100")

                Text(r.headline)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    Stat(value: "\(r.count)", label: "Compressions")
                    Stat(value: r.averageRate.map { "\(Int($0.rounded()))" } ?? "–", label: "Average rate /min",
                         color: Theme.color(for: r.averageRate, in: Guideline.rate, tolerance: 8))
                    Stat(value: "\(Int((r.rateOnTarget * 100).rounded()))%", label: "On-target rate")
                    if r.measuredDepth {
                        Stat(value: r.averageDepth.map { String(format: "%.1f", $0) } ?? "–", label: "Average depth cm",
                             color: Theme.color(for: r.averageDepth, in: Guideline.depth, tolerance: 0.6))
                    }
                    Stat(value: String(format: "%.1f s", r.longestPause), label: "Longest pause",
                         color: r.longestPause <= 2 ? Theme.good : Theme.warn)
                }
                .frame(maxWidth: 600)

                if r.compressions.contains(where: { $0.rate != nil }) {
                    RateChart(compressions: r.compressions)
                        .frame(maxWidth: 600)
                }

                Text(advice(for: r))
                    .font(.callout)
                    .padding(18)
                    .frame(maxWidth: 600, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 14) {
                    Button("Try again") { model.chooseMode() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    PrimaryButton(title: "Finish", symbol: "checkmark") { model.showFinale() }
                }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func advice(for r: PracticeResults) -> String {
        if r.count < 5 {
            return "We didn't detect many compressions. In cushion mode, push firmly straight down with the phone flat in your hands. Or try tap mode."
        }
        var tips: [String] = []
        if let rate = r.averageRate {
            if rate < Guideline.rate.lowerBound { tips.append("Speed up — aim for about two pushes a second.") }
            if rate > Guideline.rate.upperBound { tips.append("Slow down slightly — too fast and the heart can't refill between pushes.") }
        }
        if let depth = r.averageDepth {
            if depth < Guideline.depth.lowerBound { tips.append("Push harder: lock your elbows and use your body weight, not your arms.") }
            if depth > Guideline.depth.upperBound + 0.5 { tips.append("Ease off a little — 5 to 6 cm is enough.") }
        }
        if r.longestPause > 2 { tips.append("Keep going without stopping — every pause lets blood pressure fall.") }
        return tips.isEmpty ? "Excellent. That's the rhythm that keeps blood flowing to the brain." : tips.joined(separator: " ")
    }
}

private struct Stat: View {
    let value: String
    let label: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.weight(.black).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

/// Your rate over time against the 100–120 band. Swift Charts also gives
/// VoiceOver users an Audio Graph of this automatically.
private struct RateChart: View {
    let compressions: [Compression]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your rhythm")
                .font(.headline)
            Chart {
                RectangleMark(
                    xStart: .value("Start", 0),
                    xEnd: .value("End", CoachModel.practiceSeconds),
                    yStart: .value("Low", Guideline.rate.lowerBound),
                    yEnd: .value("High", Guideline.rate.upperBound)
                )
                .foregroundStyle(Theme.good.opacity(0.2))

                ForEach(compressions.filter { $0.rate != nil }) { c in
                    LineMark(
                        x: .value("Time (s)", c.time),
                        y: .value("Rate", min(170, max(50, c.rate ?? 0)))
                    )
                    .foregroundStyle(Theme.heart)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXScale(domain: 0...CoachModel.practiceSeconds)
            .chartYScale(domain: 50...170)
            .chartXAxisLabel("seconds")
            .chartYAxisLabel("per minute")
            .frame(height: 180)
            .accessibilityLabel("Compression rate over time, with the target band from 100 to 120 per minute.")
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FinaleView: View {
    @EnvironmentObject private var model: CoachModel

    private let steps: [(String, String, String)] = [
        ("phone.fill", "Call", "Call your local emergency number. Put it on speaker. Send someone for an AED."),
        ("hand.raised.fill", "Push", "Hard and fast in the centre of the chest: 5–6 cm, 100–120 a minute."),
        ("arrow.triangle.2.circlepath", "Don't stop", "Keep going until help arrives or an AED tells you to pause. Swap with someone every 2 minutes if you can.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)
                BeatingHeart(size: 70)
                Text("Three things to remember")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                VStack(spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(i + 1)")
                                .font(.title2.weight(.black))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Theme.heart, in: Circle())
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Label(step.1, systemImage: step.0).font(.headline)
                                Text(step.2).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(18)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: 600)

                Text("You don't need to be certain or perfect. Doing something is always better than doing nothing — the dispatcher on the phone will help you.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)

                Text("HandsOn teaches adult hands-only CPR based on AHA and ERC guidelines. It is a practice tool, not a certified course or medical device — consider taking a local CPR class.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)

                PrimaryButton(title: "Start over", symbol: "arrow.counterclockwise") { model.restart() }
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
}
