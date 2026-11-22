import AVFoundation

/// A tiny 3D sound stage built on `AVAudioEnvironmentNode`.
///
/// Each source (ball, defender, guide) is a mono player rendered with
/// head-related transfer functions (HRTF), so with headphones you hear it
/// in front, behind, left or right of you, and nearer or further away.
final class SpatialAudio {
    enum Source: CaseIterable {
        case ball, defender, guide
    }

    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private let interface = AVAudioPlayerNode()   // non-spatial UI sounds
    private var players: [Source: AVAudioPlayerNode] = [:]
    private let format = SoundFactory.format
    private var configObserver: NSObjectProtocol?

    init() {
        engine.attach(environment)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
        let distance = environment.distanceAttenuationParameters
        distance.distanceAttenuationModel = .inverse
        distance.referenceDistance = 1
        distance.maximumDistance = 40
        distance.rolloffFactor = 0.8
        environment.reverbParameters.enable = true
        environment.reverbParameters.level = -12
        environment.reverbParameters.loadFactoryReverbPreset(.mediumHall)

        for source in Source.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: environment, format: format)
            node.renderingAlgorithm = .HRTFHQ
            node.sourceMode = .pointSource
            node.reverbBlend = 0.12
            players[source] = node
        }

        engine.attach(interface)
        engine.connect(interface, to: engine.mainMixerNode, format: format)

        // Plugging in or removing headphones reconfigures the engine and stops it.
        configObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            self?.restart()
        }
    }

    deinit {
        if let configObserver { NotificationCenter.default.removeObserver(configObserver) }
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
        restart()
    }

    private func restart() {
        if !engine.isRunning {
            engine.prepare()
            do {
                try engine.start()
            } catch {
                print("Rattle: audio engine failed to start: \(error)")
                return
            }
        }
        for node in players.values { node.play() }
        interface.play()
    }

    /// Positions a source relative to the listener.
    /// - Parameters:
    ///   - bearing: degrees, 0 = straight ahead, positive = to your right.
    ///   - distance: metres.
    func place(_ source: Source, bearing: Double, distance: Double) {
        let radians = bearing * .pi / 180
        // AVAudio3D: +x is right, -z is forward.
        players[source]?.position = AVAudio3DPoint(
            x: Float(sin(radians) * distance),
            y: 0,
            z: Float(-cos(radians) * distance)
        )
    }

    func setVolume(_ source: Source, _ volume: Float) {
        players[source]?.volume = volume
    }

    func loop(_ source: Source, _ buffer: AVAudioPCMBuffer) {
        guard let node = players[source] else { return }
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: .loops)
        node.play()
    }

    func play(_ source: Source, _ buffer: AVAudioPCMBuffer, interrupt: Bool = true) {
        guard let node = players[source] else { return }
        node.scheduleBuffer(buffer, at: nil, options: interrupt ? .interrupts : [])
        if !node.isPlaying { node.play() }
    }

    func silence(_ source: Source) {
        players[source]?.stop()
    }

    func silenceAll() {
        for node in players.values { node.stop() }
    }

    /// Plays a non-spatial sound (whistle, chime, crowd) straight to both ears.
    func playInterface(_ buffer: AVAudioPCMBuffer) {
        interface.scheduleBuffer(buffer, at: nil, options: [])
        if !interface.isPlaying { interface.play() }
    }
}
