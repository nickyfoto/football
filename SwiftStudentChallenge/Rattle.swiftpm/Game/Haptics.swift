import CoreHaptics

/// Core Haptics feedback. A continuous "hum" grows stronger as you face the
/// sound, so players who are deaf or hard of hearing can play by touch.
final class Haptics {
    private var engine: CHHapticEngine?
    private var hum: CHHapticAdvancedPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            engine.isAutoShutdownEnabled = false
            engine.resetHandler = { [weak self] in
                self?.hum = nil
                try? self?.engine?.start()
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    func startHum() {
        guard let engine, hum == nil else { return }
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0,
            duration: 1
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            try player.start(atTime: CHHapticTimeImmediate)
            hum = player
            setHum(0)
        } catch {
            hum = nil
        }
    }

    /// - Parameter level: 0 (off) … 1 (strong).
    func setHum(_ level: Double) {
        guard let hum else { return }
        let level = Float(max(0, min(1, level)))
        let intensity = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: level, relativeTime: 0)
        let sharpness = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: level * 0.6 - 0.2, relativeTime: 0)
        try? hum.sendParameters([intensity, sharpness], atTime: CHHapticTimeImmediate)
    }

    func stopHum() {
        try? hum?.stop(atTime: CHHapticTimeImmediate)
        hum = nil
    }

    func tap(intensity: Float = 0.8, sharpness: Float = 0.6) {
        play([transient(at: 0, intensity: intensity, sharpness: sharpness)])
    }

    func celebrate() {
        play((0..<6).map { transient(at: Double($0) * 0.09, intensity: 1, sharpness: 0.4 + Float($0) * 0.1) })
    }

    private func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private func play(_ events: [CHHapticEvent]) {
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
}
