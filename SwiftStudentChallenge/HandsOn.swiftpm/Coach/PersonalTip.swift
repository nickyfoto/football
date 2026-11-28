import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// A short, personal coaching tip written from your practice numbers.
struct PersonalTip: Equatable, Sendable {
    let title: String
    let text: String
    /// True when Apple Intelligence wrote it on-device; false for the built-in rules.
    let byAppleIntelligence: Bool
}

enum TipWriter {
    /// Uses the on-device Apple Intelligence model when it's available
    /// (iOS 26+, supported device, Apple Intelligence turned on). Otherwise —
    /// or if anything goes wrong — falls back to hand-written rules, so the
    /// app always works offline on any device.
    static func write(for results: PracticeResults) async -> PersonalTip {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), results.count >= 5,
           let tip = await AppleIntelligenceCoach.write(for: results) {
            return tip
        }
        #endif
        return rules(for: results)
    }

    /// True if the on-device model can be used right now.
    static var appleIntelligenceAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return AppleIntelligenceCoach.isAvailable }
        #endif
        return false
    }

    /// Deterministic tips from the guideline numbers.
    static func rules(for r: PracticeResults) -> PersonalTip {
        if r.count < 5 {
            return PersonalTip(
                title: "Let's get you moving",
                text: "We didn't detect many compressions. In cushion mode, push firmly straight down with the phone flat in your hands, or try tap mode.",
                byAppleIntelligence: false)
        }
        var tips: [String] = []
        if r.longestPause > 2 { tips.append("Keep going without stopping — every pause lets blood pressure fall.") }
        if let rate = r.averageRate {
            if rate < Guideline.rate.lowerBound { tips.append("Speed up — aim for about two pushes a second.") }
            if rate > Guideline.rate.upperBound { tips.append("Slow down slightly — too fast and the heart can't refill between pushes.") }
        }
        if let depth = r.averageDepth {
            if depth < Guideline.depth.lowerBound { tips.append("Push harder: lock your elbows and use your body weight, not your arms.") }
            if depth > Guideline.depth.upperBound + 0.5 { tips.append("Ease off a little — 5 to 6 cm is enough.") }
        }
        if tips.isEmpty {
            return PersonalTip(title: "That's the rhythm",
                               text: "Excellent. That's the rhythm that keeps blood flowing to the brain. Keep it up until help arrives.",
                               byAppleIntelligence: false)
        }
        return PersonalTip(title: "One thing to work on", text: tips.prefix(2).joined(separator: " "), byAppleIntelligence: false)
    }
}

#if canImport(FoundationModels)

/// The structure we ask the model to fill in (guided generation), so we
/// always get a short title and a short tip — never free-form text.
@available(iOS 26.0, *)
@Generable
struct GeneratedTip {
    @Guide(description: "An encouraging title of 2 to 5 words, no punctuation at the end.")
    var title: String

    @Guide(description: "One or two short sentences, under 40 words in total, addressed to the learner as 'you'.")
    var tip: String
}

@available(iOS 26.0, *)
enum AppleIntelligenceCoach {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func write(for r: PracticeResults) async -> PersonalTip? {
        guard isAvailable else { return nil }

        let session = LanguageModelSession(instructions: """
            You are a friendly CPR instructor giving feedback after a 30-second practice of adult \
            hands-only chest compressions on a cushion. Guideline targets: 100 to 120 compressions \
            per minute, 5 to 6 cm deep, full chest recoil, and no pauses longer than 2 seconds.
            Rules:
            - Focus on the single most important thing to improve, in this order: pauses, rate, depth. \
              If everything is on target, praise them and remind them to keep going until help arrives.
            - Give one concrete physical cue, such as locking the elbows, keeping shoulders over the \
              hands, using body weight, counting out loud, or letting the chest come all the way up.
            - Use only the numbers provided. Do not invent measurements.
            - Do not diagnose, mention medication, or give advice beyond CPR technique.
            - Be warm and brief.
            """)

        do {
            let response = try await session.respond(
                to: prompt(for: r),
                generating: GeneratedTip.self,
                options: GenerationOptions(temperature: 0.4)
            )
            let title = response.content.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = response.content.tip.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, !text.isEmpty, text.count <= 320 else { return nil }
            return PersonalTip(title: title, text: text, byAppleIntelligence: true)
        } catch {
            // Guardrails, an unsupported language, or the model being busy:
            // the rule-based tip takes over.
            return nil
        }
    }

    static func prompt(for r: PracticeResults) -> String {
        var lines = ["Practice results:"]
        lines.append("- Compressions: \(r.count) in \(Int(r.duration.rounded())) seconds")
        if let rate = r.averageRate {
            lines.append("- Average rate: \(Int(rate.rounded())) per minute")
        }
        lines.append("- Compressions at the target rate: \(Int((r.rateOnTarget * 100).rounded()))%")
        if let depth = r.averageDepth {
            lines.append(String(format: "- Average depth: %.1f cm", depth))
        } else {
            lines.append("- Depth: not measured (the learner tapped the screen instead of pushing on a cushion)")
        }
        if let onTarget = r.depthOnTarget {
            lines.append("- Compressions at the target depth: \(Int((onTarget * 100).rounded()))%")
        }
        lines.append(String(format: "- Longest pause: %.1f seconds", r.longestPause))
        lines.append("- Overall score: \(r.score) out of 100")
        lines.append("Write their personal tip.")
        return lines.joined(separator: "\n")
    }
}

#endif
