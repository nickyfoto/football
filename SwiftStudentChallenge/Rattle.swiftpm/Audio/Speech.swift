import AVFoundation
import UIKit

/// Renders short phrases (“Voy!”, “Here!”) with the on-device speech
/// synthesiser into mono buffers, so they can be placed in 3D space like any
/// other sound. No network, no recordings.
final class VoiceBaker {
    private var active: [AVSpeechSynthesizer] = []

    func bake(_ text: String,
              pitch: Float,
              rate: Float = AVSpeechUtteranceDefaultSpeechRate,
              completion: @escaping (AVAudioPCMBuffer?) -> Void) {
        let synth = AVSpeechSynthesizer()
        active.append(synth)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = pitch
        utterance.rate = rate
        utterance.volume = 1

        var samples: [Float] = []
        var sourceRate: Double = 22_050
        var finished = false

        // Everything below runs on the main queue, so no locking is needed.
        let finish: () -> Void = { [weak self] in
            guard !finished else { return }
            finished = true
            completion(SoundFactory.prepareVoice(samples, sourceRate: sourceRate))
            self?.active.removeAll { $0 === synth }
        }

        synth.write(utterance) { buffer in
            guard let pcm = buffer as? AVAudioPCMBuffer else { return }
            let count = Int(pcm.frameLength)
            let rate = pcm.format.sampleRate
            var chunk = [Float](repeating: 0, count: count)
            if let data = pcm.floatChannelData {
                for i in 0..<count { chunk[i] = data[0][i] }
            } else if let data = pcm.int16ChannelData {
                for i in 0..<count { chunk[i] = Float(data[0][i]) / 32_768 }
            } else if let data = pcm.int32ChannelData {
                for i in 0..<count { chunk[i] = Float(data[0][i]) / 2_147_483_648 }
            }
            DispatchQueue.main.async {
                if count == 0 {
                    finish()          // a zero-length buffer marks the end
                } else {
                    sourceRate = rate
                    samples.append(contentsOf: chunk)
                }
            }
        }

        // Safety net: never wait forever on the synthesiser.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: finish)
    }
}

/// Spoken coaching, so the whole experience works with your eyes closed.
/// When VoiceOver is running, announcements go through VoiceOver instead,
/// so the two voices never talk over each other.
final class Narrator {
    private let synth = AVSpeechSynthesizer()

    func say(_ text: String) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
            return
        }
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.prefersAssistiveTechnologySettings = true
        synth.speak(utterance)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }
}
