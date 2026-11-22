import Foundation

enum Stage: Hashable {
    case welcome
    case story
    case intro(Drill)
    case play(Drill)
    case finale
}

/// The three skills every blind-football player relies on.
enum Drill: Int, CaseIterable, Hashable {
    case locate, voy, shoot

    struct Step: Identifiable {
        let symbol: String
        let text: String
        var id: String { text }
    }

    var number: Int { rawValue + 1 }

    var next: Drill? { Drill(rawValue: rawValue + 1) }

    var title: String {
        switch self {
        case .locate: return "Find the Ball"
        case .voy:    return "Voy!"
        case .shoot:  return "Listen and Shoot"
        }
    }

    var symbol: String {
        switch self {
        case .locate: return "ear"
        case .voy:    return "figure.run"
        case .shoot:  return "soccerball"
        }
    }

    var tagline: String {
        switch self {
        case .locate:
            return "The ball is fitted with metal noisemakers. When it rolls, it rattles — that's how players track it."
        case .voy:
            return "A defender must call “Voy!” — Spanish for “I'm going” — before tackling, so players never collide blind."
        case .shoot:
            return "A guide stands behind the goal, knocks on each post and calls out, so the striker can aim by ear."
        }
    }

    var steps: [Step] {
        switch self {
        case .locate:
            return [
                Step(symbol: "rotate.3d", text: "Turn your body with the device, or drag left and right, to look around."),
                Step(symbol: "ear", text: "When the rattle sounds straight ahead, you're facing the ball."),
                Step(symbol: "hand.tap", text: "Tap anywhere to trap it.")
            ]
        case .voy:
            return [
                Step(symbol: "ear", text: "You're dribbling. Listen for a defender calling “Voy!”"),
                Step(symbol: "arrow.left.arrow.right", text: "Swipe — or tap that half of the screen — away from the voice."),
                Step(symbol: "timer", text: "Move fast: they get closer with every call.")
            ]
        case .shoot:
            return [
                Step(symbol: "speaker.wave.2", text: "The guide knocks the left post, the right post, then calls “Here!” from the middle."),
                Step(symbol: "rotate.3d", text: "Turn until the call is dead ahead."),
                Step(symbol: "arrow.up", text: "Tap or swipe up to shoot.")
            ]
        }
    }

    var spokenIntro: String {
        "Drill \(number). \(title). " + tagline + " " + steps.map(\.text).joined(separator: " ")
    }

    /// Short label used by VoiceOver for the play surface.
    var surfaceLabel: String {
        switch self {
        case .locate: return "Pitch. Swipe up or down to turn. Double tap to trap the ball."
        case .voy:    return "Pitch. Use the actions rotor to dodge left or right."
        case .shoot:  return "Pitch. Swipe up or down to turn. Double tap to shoot."
        }
    }
}

struct Marker: Identifiable {
    enum Kind { case ball, defender, guide, goal }
    let id: String
    let kind: Kind
    /// Degrees relative to where you face. 0 = ahead, positive = right.
    let bearing: Double
    /// Metres.
    let distance: Double
}

struct Pulse: Equatable {
    let id = UUID()
    let good: Bool
}

/// Normalises any angle to −180…180.
func wrap(_ degrees: Double) -> Double {
    var a = degrees.truncatingRemainder(dividingBy: 360)
    if a > 180 { a -= 360 }
    if a < -180 { a += 360 }
    return a
}
