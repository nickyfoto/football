import Foundation

/// One detected chest compression.
struct Compression: Identifiable, Equatable {
    let id: Int
    /// Seconds since the practice started.
    let time: Double
    /// Compressions per minute, from the last few intervals. `nil` for the first one.
    let rate: Double?
    /// Estimated depth in centimetres. `nil` when depth can't be measured (tap mode).
    let depth: Double?
}

/// Turns raw vertical acceleration into compressions — rate and depth.
///
/// Pure Swift with no Apple-framework dependencies, so it can be tested anywhere.
///
/// How it works:
/// * At the bottom of each push your hands decelerate hard, which shows up as
///   a sharp *upward* acceleration spike. Each spike is one compression.
/// * Depth comes from integrating acceleration twice (acceleration → velocity
///   → position). Leaky integrators stop sensor bias from drifting the result,
///   and the depth of one compression is the peak-to-peak travel between
///   two spikes.
struct CompressionDetector {
    // Tunables
    var minimumInterval = 0.27          // s — faster than ~220/min is noise
    var minimumPeak = 1.2               // m/s²
    var relativePeak = 0.35             // fraction of the recent typical peak

    // Filter state
    private var lowPassed = 0.0
    private var slow = 0.0              // tracks bias / gravity leakage
    private var velocity = 0.0
    private var position = 0.0
    private var lastTime: Double?

    // Peak state
    private var armed = true
    private var candidate: (time: Double, value: Double)?
    private var typicalPeak = 3.0
    private var lastPeakTime: Double?
    private var intervals: [Double] = []
    private var cycleMin = Double.infinity
    private var cycleMax = -Double.infinity
    private var count = 0

    /// Feed one sample.
    /// - Parameters:
    ///   - time: seconds (monotonic).
    ///   - upwardAcceleration: m/s², positive = away from the ground, gravity removed.
    ///   - measureDepth: false for sources that can't report depth.
    /// - Returns: a compression if this sample completed one.
    mutating func add(time: Double, upwardAcceleration a: Double, measureDepth: Bool = true) -> Compression? {
        let dt: Double
        if let lastTime { dt = max(0.001, min(0.05, time - lastTime)) } else { dt = 0.01 }
        lastTime = time

        // Band-limit: ~8 Hz low-pass, ~0.3 Hz high-pass.
        lowPassed += (1 - exp(-dt * 2 * .pi * 8)) * (a - lowPassed)
        slow += (1 - exp(-dt * 2 * .pi * 0.3)) * (lowPassed - slow)
        let signal = lowPassed - slow

        // Double integration with leak (time constant ~3 s).
        let leak = exp(-dt / 3)
        velocity = velocity * leak + signal * dt
        position = position * leak + velocity * dt
        cycleMin = min(cycleMin, position)
        cycleMax = max(cycleMax, position)

        // Peak picking with hysteresis: arm when the signal goes negative,
        // track the maximum while above threshold, commit once it falls back.
        let threshold = max(minimumPeak, relativePeak * typicalPeak)
        if signal < 0 { armed = true }

        if armed && signal > threshold {
            if candidate == nil || signal > candidate!.value {
                candidate = (time, signal)
            }
            return nil
        }

        guard let peak = candidate, signal < threshold * 0.5 else { return nil }
        candidate = nil
        armed = false

        if let last = lastPeakTime, peak.time - last < minimumInterval { return nil }

        typicalPeak = typicalPeak * 0.8 + peak.value * 0.2
        return commit(at: peak.time, measureDepth: measureDepth)
    }

    /// Records a compression from a source with no acceleration (screen taps).
    mutating func addTap(time: Double) -> Compression? {
        if let last = lastPeakTime, time - last < minimumInterval { return nil }
        return commit(at: time, measureDepth: false)
    }

    private mutating func commit(at time: Double, measureDepth: Bool) -> Compression {
        if let last = lastPeakTime {
            let interval = time - last
            // A long pause resets the rhythm instead of reporting a silly rate.
            if interval < 2 {
                intervals.append(interval)
                if intervals.count > 4 { intervals.removeFirst() }
            } else {
                intervals.removeAll()
            }
        }
        lastPeakTime = time

        var rate: Double?
        if !intervals.isEmpty {
            // Mean of the last few intervals, ignoring the single most extreme one.
            var recent = intervals
            if recent.count >= 4 {
                let mean = recent.reduce(0, +) / Double(recent.count)
                if let worst = recent.indices.max(by: { abs(recent[$0] - mean) < abs(recent[$1] - mean) }) {
                    recent.remove(at: worst)
                }
            }
            rate = 60 / (recent.reduce(0, +) / Double(recent.count))
        }

        var depth: Double?
        if measureDepth && cycleMax > cycleMin && count > 0 {
            // ×1.03 compensates the small amplitude loss of the band-pass filters.
            depth = (cycleMax - cycleMin) * 100 * 1.03
        }
        cycleMin = position
        cycleMax = position

        count += 1
        return Compression(id: count, time: time, rate: rate, depth: depth)
    }
}

/// Guideline targets (adult hands-only CPR, AHA 2020 / ERC 2021).
enum Guideline {
    static let rate: ClosedRange<Double> = 100...120   // per minute
    static let depth: ClosedRange<Double> = 5...6      // cm
    static let beatsPerMinute = 110.0
}
