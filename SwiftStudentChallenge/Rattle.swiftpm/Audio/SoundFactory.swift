import AVFoundation

/// Every sound in Rattle is synthesised in code at launch, so the playground
/// ships with no audio files and works fully offline.
enum SoundFactory {
    static let sampleRate: Double = 44_100

    /// Mono float format. The 3D environment node only spatialises mono input.
    static let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

    // MARK: - Sounds

    /// The ball: blind-football balls carry metal noisemakers that rattle as
    /// they roll. Short metallic bursts at an uneven ~9 Hz, looped seamlessly.
    static func rattleLoop(seconds: Double = 2.0, hitsPerSecond: Double = 9) -> AVAudioPCMBuffer {
        let n = Int(seconds * sampleRate)
        var out = [Float](repeating: 0, count: n)
        let burst = Int(0.04 * sampleRate)
        var t = 0.0
        while t < seconds - 0.06 {
            let start = Int(t * sampleRate)
            let f1 = Double.random(in: 2_800...3_600)
            let f2 = Double.random(in: 4_200...5_200)
            let f3 = Double.random(in: 6_000...7_400)
            let amp = Float.random(in: 0.35...0.75)
            for i in 0..<burst where start + i < n {
                let tt = Double(i) / sampleRate
                let env = exp(-tt * 140)
                let tone = 0.5 * sin(2 * .pi * f1 * tt)
                    + 0.35 * sin(2 * .pi * f2 * tt)
                    + 0.25 * sin(2 * .pi * f3 * tt)
                let grit = Double.random(in: -0.3...0.3)
                out[start + i] += Float((tone + grit) * env) * amp
            }
            t += (1 / hitsPerSecond) * Double.random(in: 0.55...1.45)
        }
        normalize(&out, peak: 0.8)
        return buffer(out)
    }

    /// The guide knocking on a metal goalpost.
    static func knock() -> AVAudioPCMBuffer {
        render(seconds: 0.3) { t in
            let body = 0.6 * sin(2 * .pi * 520 * t)
                + 0.4 * sin(2 * .pi * 1_340 * t)
                + 0.25 * sin(2 * .pi * 2_710 * t)
            let click = t < 0.004 ? Double.random(in: -1...1) : 0
            return (body + click) * exp(-t * 26)
        }
    }

    /// Referee's whistle (starts each drill).
    static func whistle() -> AVAudioPCMBuffer {
        var phase = 0.0
        let length = 0.55
        return render(seconds: length) { t in
            let f = 2_900 + 140 * sin(2 * .pi * 28 * t)
            phase += 2 * .pi * f / sampleRate
            let env = min(1, t / 0.02) * min(1, (length - t) / 0.08)
            return (0.8 * sin(phase) + Double.random(in: -0.08...0.08)) * env
        }
    }

    /// Two-note chime when you trap the ball.
    static func chime() -> AVAudioPCMBuffer {
        render(seconds: 0.45) { t in
            let a = t < 0.12 ? sin(2 * .pi * 660 * t) * exp(-t * 18) : 0
            let tb = t - 0.12
            let b = tb >= 0 ? sin(2 * .pi * 990 * tb) * exp(-tb * 9) : 0
            return 0.7 * (a + b)
        }
    }

    /// Foot meeting ball.
    static func kick() -> AVAudioPCMBuffer {
        var lp = 0.0
        return render(seconds: 0.18) { t in
            lp += 0.25 * (Double.random(in: -1...1) - lp)
            let thump = sin(2 * .pi * (140 - 300 * t) * t)
            return (0.8 * thump + 0.6 * lp) * exp(-t * 30)
        }
    }

    /// Missed shot / tackle.
    static func thud() -> AVAudioPCMBuffer {
        var lp = 0.0
        return render(seconds: 0.4) { t in
            lp += 0.08 * (Double.random(in: -1...1) - lp)
            let low = sin(2 * .pi * (90 - 60 * t) * t)
            return (0.9 * low + 1.5 * lp) * exp(-t * 11)
        }
    }

    /// Air rushing past as you slip a defender.
    static func swoosh() -> AVAudioPCMBuffer {
        var lp = 0.0
        let length = 0.45
        return render(seconds: length) { t in
            let p = t / length
            let k = 0.03 + 0.4 * p          // filter opens as it passes
            lp += k * (Double.random(in: -1...1) - lp)
            return lp * sin(.pi * p) * 2.2
        }
    }

    /// The crowd. In blind football the stands stay silent during play so the
    /// players can hear — and then erupt when a goal goes in.
    static func cheer() -> AVAudioPCMBuffer {
        let length = 3.2
        let n = Int(length * sampleRate)
        var out = [Float](repeating: 0, count: n)
        var lp = 0.0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            lp += 0.06 * (Double.random(in: -1...1) - lp)
            let env = min(1, t / 0.35) * exp(-max(0, t - 0.8) * 1.3)
            out[i] = Float(lp * env * 3)
        }
        // Hundreds of hand claps on top.
        let clap = Int(0.007 * sampleRate)
        for _ in 0..<700 {
            let t = Double.random(in: 0.1...(length - 0.1))
            let start = Int(t * sampleRate)
            let gain = Float(exp(-max(0, t - 0.9) * 1.1)) * Float.random(in: 0.1...0.35)
            for j in 0..<clap where start + j < n {
                out[start + j] += Float.random(in: -1...1) * gain * Float(exp(-Double(j) / Double(clap) * 3))
            }
        }
        normalize(&out, peak: 0.85)
        return buffer(out)
    }

    /// Used only if on-device speech synthesis is unavailable: a short
    /// vowel-like shout so the drill still works.
    static func shout(pitch: Double) -> AVAudioPCMBuffer {
        var phase = 0.0
        var lp = 0.0
        let length = 0.38
        return render(seconds: length) { t in
            let f = pitch * (1.15 - 0.3 * t / length)
            phase += f / sampleRate
            let saw = 2 * (phase - floor(phase)) - 1
            lp += 0.3 * (saw - lp)
            let env = min(1, t / 0.03) * min(1, (length - t) / 0.12)
            return lp * env
        }
    }

    // MARK: - Helpers

    static func render(seconds: Double, _ sample: (Double) -> Double) -> AVAudioPCMBuffer {
        let n = Int(seconds * sampleRate)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            out[i] = Float(sample(Double(i) / sampleRate))
        }
        normalize(&out, peak: 0.85)
        return buffer(out)
    }

    static func buffer(_ samples: [Float]) -> AVAudioPCMBuffer {
        let count = max(1, samples.count)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(count))!
        buf.frameLength = AVAudioFrameCount(count)
        let channel = buf.floatChannelData![0]
        for i in 0..<count {
            channel[i] = i < samples.count ? samples[i] : 0
        }
        return buf
    }

    static func normalize(_ samples: inout [Float], peak: Float) {
        let maxValue = samples.reduce(0) { max($0, abs($1)) }
        guard maxValue > 0 else { return }
        let gain = peak / maxValue
        for i in samples.indices { samples[i] *= gain }
    }

    /// Linear resample to the engine's rate, trim silence, normalise, fade edges.
    static func prepareVoice(_ samples: [Float], sourceRate: Double) -> AVAudioPCMBuffer? {
        guard samples.count > 100, sourceRate > 0 else { return nil }
        let ratio = sourceRate / sampleRate
        let outCount = Int(Double(samples.count) / ratio)
        var out = [Float](repeating: 0, count: outCount)
        for i in 0..<outCount {
            let x = Double(i) * ratio
            let i0 = Int(x)
            let i1 = min(i0 + 1, samples.count - 1)
            let f = Float(x - Double(i0))
            out[i] = samples[i0] * (1 - f) + samples[i1] * f
        }
        let threshold: Float = 0.01
        guard let first = out.firstIndex(where: { abs($0) > threshold }),
              let last = out.lastIndex(where: { abs($0) > threshold }),
              last > first else { return nil }
        var trimmed = Array(out[first...last])
        normalize(&trimmed, peak: 0.9)
        let fade = min(200, trimmed.count / 4)
        for i in 0..<fade {
            let g = Float(i) / Float(fade)
            trimmed[i] *= g
            trimmed[trimmed.count - 1 - i] *= g
        }
        return buffer(trimmed)
    }
}
