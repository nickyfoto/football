import SwiftUI
import QuartzCore

enum Stage: Hashable {
    case welcome
    case scene(Int)
    case hands
    case mode
    case practice
    case results
    case finale
}

enum InputMode: Hashable {
    /// Phone held in your hands, pushing into a cushion. Measures rate and depth.
    case motion
    /// Tapping the screen to the rhythm. Rate only — works on any device, including Mac.
    case tap
}

/// The emergency walkthrough before the practice.
struct SceneStep {
    let symbol: String
    let title: String
    let body: String
    let action: String
}

let sceneSteps: [SceneStep] = [
    SceneStep(symbol: "exclamationmark.triangle",
              title: "Check it's safe",
              body: "Someone has collapsed in front of you. Before you go to them, look around: no traffic, fire or electricity.",
              action: "It's safe"),
    SceneStep(symbol: "hand.wave",
              title: "Check for a response",
              body: "Tap their shoulders firmly and shout, “Are you OK?”",
              action: "No response"),
    SceneStep(symbol: "lungs",
              title: "Check breathing",
              body: "Watch their chest for up to 10 seconds. Occasional gasps are not normal breathing.",
              action: "Not breathing normally"),
    SceneStep(symbol: "phone.arrow.up.right",
              title: "Call for help",
              body: "Call your local emergency number and put the phone on speaker — the dispatcher will guide you. Send someone to find an AED (defibrillator).",
              action: "I've called (practice)")
]

/// Runs the whole experience: walkthrough, practice session, coaching and results.
@MainActor
final class CoachModel: ObservableObject {
    nonisolated static let practiceSeconds = 30.0

    @Published private(set) var stage: Stage = .welcome
    @Published var inputMode: InputMode = .motion
    @Published var beatOn = true {
        // Applies during the countdown too, not just once practice is running.
        didSet { if stage == .practice { updateBeat() } }
    }

    // Live practice state
    @Published private(set) var countdown: Int?
    @Published private(set) var isRunning = false
    @Published private(set) var elapsed = 0.0
    @Published private(set) var compressions: [Compression] = []
    @Published private(set) var currentRate: Double?
    @Published private(set) var currentDepth: Double?
    @Published private(set) var prompt = ""

    private let sensor = MotionSensor()
    private let metronome = Metronome()
    private let coach = Coach()
    private let haptics = Haptics()
    private var detector = CompressionDetector()
    private var startTime = 0.0
    private var sensorStart: Double?
    private var ticker: Timer?
    private var lastAdvice = -10.0
    private var lastPraise = -10.0
    private var generation = 0

    var motionAvailable: Bool { sensor.isAvailable }

    init() {
        if !sensor.isAvailable { inputMode = .tap }
    }

    // MARK: - Navigation

    func begin() {
        stage = .scene(0)
        say(sceneSteps[0].body)
    }

    func advanceScene(from index: Int) {
        let next = index + 1
        if next < sceneSteps.count {
            stage = .scene(next)
            say(sceneSteps[next].body)
        } else {
            stage = .hands
            say("Now, place your hands. Heel of one hand in the centre of the chest, other hand on top. Arms straight, shoulders over your hands.")
        }
    }

    func chooseMode() {
        stage = .mode
        say(motionAvailable
            ? "Choose how to practise. With a cushion, your phone measures how fast and how deep you push."
            : "Tap the screen to the beat to practise the rhythm.")
    }

    func startPractice() {
        stage = .practice
        compressions = []
        currentRate = nil
        currentDepth = nil
        elapsed = 0
        prompt = ""
        detector = CompressionDetector()
        UIApplication.shared.isIdleTimerDisabled = true
        generation += 1
        let token = generation

        // Beat starts with the countdown so you can lock onto the rhythm.
        updateBeat()
        let instructions = inputMode == .motion
            ? "Push to the beat. Hard and fast. Three, two, one, go."
            : "Tap to the beat. Three, two, one, go."
        coach.say(instructions)
        countdown = 3
        for (i, n) in [2, 1].enumerated() {
            after(Double(i + 1) * 1.1, token) { [weak self] in self?.countdown = n }
        }
        after(3.3, token) { [weak self] in self?.go() }
    }

    func stopPractice() {
        finishPractice()
    }

    func showFinale() {
        stage = .finale
        say("Remember: call, push hard and fast in the centre of the chest, and don't stop until help arrives.")
    }

    func restart() {
        coach.stop()
        stage = .welcome
    }

    func say(_ text: String, interrupt: Bool = true) {
        coach.say(text, interrupt: interrupt)
    }

    // MARK: - Practice

    private func go() {
        countdown = nil
        isRunning = true
        startTime = CACurrentMediaTime()
        sensorStart = nil
        lastAdvice = 0
        lastPraise = 0
        if inputMode == .motion {
            sensor.start { [weak self] time, up in
                MainActor.assumeIsolated { self?.handleMotion(time: time, up: up) }
            }
        }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func handleMotion(time: Double, up: Double) {
        guard isRunning else { return }
        if sensorStart == nil { sensorStart = time - (CACurrentMediaTime() - startTime) }
        let t = time - (sensorStart ?? time)
        if let c = detector.add(time: t, upwardAcceleration: up) {
            record(c)
        }
    }

    /// A screen tap (or space bar) in tap mode.
    func tapCompression() {
        guard isRunning, inputMode == .tap else { return }
        if let c = detector.addTap(time: CACurrentMediaTime() - startTime) {
            record(c)
        }
    }

    private func record(_ c: Compression) {
        compressions.append(c)
        let recent = compressions.suffix(5)
        let rates = recent.compactMap(\.rate)
        let depths = recent.compactMap(\.depth)
        currentRate = rates.isEmpty ? nil : rates.reduce(0, +) / Double(rates.count)
        currentDepth = depths.isEmpty ? nil : depths.reduce(0, +) / Double(depths.count)
        if inputMode == .tap { haptics.tap(intensity: 0.4, sharpness: 0.2) }
    }

    private func tick() {
        guard isRunning else { return }
        elapsed = CACurrentMediaTime() - startTime
        if elapsed >= Self.practiceSeconds {
            finishPractice()
            return
        }
        coachIfNeeded()
    }

    /// One short, specific prompt at a time — never more than every 3 seconds.
    private func coachIfNeeded() {
        guard elapsed - lastAdvice >= 3 else { return }
        let sinceLast = elapsed - (compressions.last?.time ?? 0)

        var advice: String?
        if sinceLast > 2.5 && elapsed > 2.5 {
            advice = compressions.isEmpty
                ? (inputMode == .motion ? "Push down into the cushion, to the beat." : "Tap the screen, to the beat.")
                : "Keep going — don't stop."
        } else if compressions.count >= 5, let rate = currentRate {
            if rate < Guideline.rate.lowerBound - 3 {
                advice = "Faster."
            } else if rate > Guideline.rate.upperBound + 3 {
                advice = "Slow down a little."
            } else if let depth = currentDepth, depth < Guideline.depth.lowerBound - 0.3 {
                advice = "Push harder."
            } else if let depth = currentDepth, depth > Guideline.depth.upperBound + 0.5 {
                advice = "A little less deep."
            } else if elapsed - lastPraise >= 8 {
                advice = ["Great rhythm. Keep going.", "That's it. Hard and fast.", "Perfect. Stay with the beat."].randomElement()
                lastPraise = elapsed
            }
        }

        guard let advice else { return }
        lastAdvice = elapsed
        prompt = advice
        coach.say(advice)
    }

    private func finishPractice() {
        generation += 1
        isRunning = false
        countdown = nil
        ticker?.invalidate()
        ticker = nil
        sensor.stop()
        metronome.stop()
        haptics.stopBeat()
        UIApplication.shared.isIdleTimerDisabled = false
        stage = .results
        let r = results
        if r.score >= 80 { haptics.success() }
        coach.say(r.spokenSummary)
    }

    private func updateBeat() {
        if beatOn {
            metronome.start()
            haptics.startBeat()
        } else {
            metronome.stop()
            haptics.stopBeat()
        }
    }

    private func after(_ seconds: Double, _ token: Int, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.generation == token else { return }
                work()
            }
        }
    }

    // MARK: - Results

    var results: PracticeResults {
        PracticeResults(compressions: compressions, duration: max(1, min(elapsed, Self.practiceSeconds)), measuredDepth: inputMode == .motion)
    }
}

struct PracticeResults: Sendable {
    let compressions: [Compression]
    let duration: Double
    let measuredDepth: Bool

    var count: Int { compressions.count }

    var averageRate: Double? {
        let rates = compressions.compactMap(\.rate)
        return rates.isEmpty ? nil : rates.reduce(0, +) / Double(rates.count)
    }

    var averageDepth: Double? {
        let depths = compressions.compactMap(\.depth)
        return depths.isEmpty ? nil : depths.reduce(0, +) / Double(depths.count)
    }

    /// Share of compressions with a rate inside 100–120 (with a little tolerance).
    var rateOnTarget: Double {
        let rates = compressions.compactMap(\.rate)
        guard !rates.isEmpty else { return 0 }
        let tolerant = (Guideline.rate.lowerBound - 3)...(Guideline.rate.upperBound + 3)
        return Double(rates.filter { tolerant.contains($0) }.count) / Double(rates.count)
    }

    var depthOnTarget: Double? {
        let depths = compressions.compactMap(\.depth)
        guard measuredDepth, !depths.isEmpty else { return nil }
        let tolerant = (Guideline.depth.lowerBound - 0.3)...(Guideline.depth.upperBound + 0.5)
        return Double(depths.filter { tolerant.contains($0) }.count) / Double(depths.count)
    }

    /// Longest time without a compression, including the start and end.
    var longestPause: Double {
        var times = [0.0] + compressions.map(\.time) + [duration]
        times.sort()
        return zip(times, times.dropFirst()).map { $1 - $0 }.max() ?? duration
    }

    /// 0–100. Rhythm, depth (when measured) and not stopping.
    var score: Int {
        guard count >= 5 else { return 0 }
        // Pauses matter: blood pressure drops within seconds of stopping.
        let pausePenalty = max(0, min(1, (longestPause - 1.5) / 3.5))
        let continuity = 1 - pausePenalty
        let value: Double
        if let depthOnTarget {
            value = 0.4 * rateOnTarget + 0.35 * depthOnTarget + 0.25 * continuity
        } else {
            value = 0.75 * rateOnTarget + 0.25 * continuity
        }
        return Int((value * 100).rounded())
    }

    var headline: String {
        switch score {
        case 85...: return "You could keep someone alive."
        case 60..<85: return "Nearly there."
        case 1..<60: return "Good start — practise once more."
        default: return "Let's try that again."
        }
    }

    var spokenSummary: String {
        var parts = ["Time. You did \(count) compressions."]
        if let averageRate { parts.append("Your average rate was \(Int(averageRate.rounded())) per minute.") }
        if let averageDepth { parts.append(String(format: "Average depth about %.1f centimetres.", averageDepth)) }
        parts.append("Score: \(score) out of 100. \(headline)")
        return parts.joined(separator: " ")
    }
}
