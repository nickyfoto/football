import AVFoundation
import CoreHaptics
import UIKit

/// A sample-accurate metronome at 110 beats per minute — the middle of the
/// 100–120 guideline range. One beat is synthesised and looped, so it never
/// drifts. Works offline with no audio files.
final class Metronome {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private lazy var beat = makeBeat(bpm: Guideline.beatsPerMinute)

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        // .playback so the beat plays even with the silent switch on.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        if !engine.isRunning {
            engine.prepare()
            try? engine.start()
        }
        player.stop()
        player.scheduleBuffer(beat, at: nil, options: .loops)
        player.play()
    }

    func stop() {
        player.stop()
    }

    private func makeBeat(bpm: Double) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let length = Int((rate * 60 / bpm).rounded())
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(length))!
        buffer.frameLength = AVAudioFrameCount(length)
        let out = buffer.floatChannelData![0]
        for i in 0..<length {
            let t = Double(i) / rate
            // A short, woody click: two damped partials and a tiny noise transient.
            let tone = 0.6 * sin(2 * .pi * 1_250 * t) + 0.3 * sin(2 * .pi * 2_600 * t)
            let click = t < 0.002 ? Double.random(in: -0.5...0.5) : 0
            out[i] = Float((tone + click) * exp(-t * 90) * 0.7)
        }
        return buffer
    }
}

/// Spoken coaching. When VoiceOver is running, prompts are posted as
/// VoiceOver announcements instead so the two voices never overlap.
final class Coach {
    private let synth = AVSpeechSynthesizer()

    func say(_ text: String, interrupt: Bool = true) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
            return
        }
        if interrupt, synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.53
        utterance.prefersAssistiveTechnologySettings = true
        synth.speak(utterance)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}

/// Core Haptics: a beat you can *feel* (useful for Deaf and hard-of-hearing
/// learners, or in a loud room) plus a tap for each compression detected.
final class Haptics {
    private var engine: CHHapticEngine?
    private var beatPlayer: CHHapticAdvancedPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = false
            engine.playsHapticsOnly = true
            engine.resetHandler = { [weak self] in
                self?.beatPlayer = nil
                try? self?.engine?.start()
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    func startBeat() {
        guard let engine, beatPlayer == nil else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            player.loopEnd = 60 / Guideline.beatsPerMinute
            try player.start(atTime: CHHapticTimeImmediate)
            beatPlayer = player
        } catch {
            beatPlayer = nil
        }
    }

    func stopBeat() {
        try? beatPlayer?.stop(atTime: CHHapticTimeImmediate)
        beatPlayer = nil
    }

    func tap(intensity: Float = 0.5, sharpness: Float = 0.3) {
        guard let engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {}
    }

    func success() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) { [weak self] in
                self?.tap(intensity: 1, sharpness: 0.5 + Float(i) * 0.2)
            }
        }
    }
}
