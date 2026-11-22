import SwiftUI
import AVFoundation
import CoreMotion
import QuartzCore

/// Runs the whole experience: stages, the three drills, sound placement,
/// haptics and spoken feedback. All methods are called on the main thread.
@MainActor
final class GameModel: ObservableObject {
    nonisolated static let rounds = 3
    /// A blind-football goal is 3 m wide. From 9 m away that's ±9.5°.
    nonisolated static let goalHalfAngle = 9.5
    nonisolated static let guideDistance = 9.0

    // MARK: Published state

    @Published private(set) var stage: Stage = .welcome
    @Published private(set) var heading: Double = 0            // world degrees, clockwise
    @Published private(set) var round = 0
    @Published private(set) var status = ""
    @Published private(set) var soundCaption = ""
    @Published private(set) var markers: [Marker] = []
    @Published private(set) var alignment: Double = 0          // 0…1: how squarely you face the target
    @Published private(set) var pulse: Pulse?
    @Published private(set) var calls = 0                      // bumps on every “Voy!” for the visual ring

    @Published private(set) var trapTries = 0
    @Published private(set) var trapped = 0
    @Published private(set) var dodged = 0
    @Published private(set) var goals = 0

    /// Shows a top-down radar and directional captions. Off by default —
    /// the game is designed to be played with your ears.
    @Published var seeSound = false
    @Published var turnWithDevice = true {
        didSet { updateMotion() }
    }

    var motionAvailable: Bool { motion.isDeviceMotionAvailable }

    // MARK: Engines

    private let audio = SpatialAudio()
    private let haptics = Haptics()
    private let narrator = Narrator()
    private let baker = VoiceBaker()
    private let motion = CMMotionManager()
    private var lastMotionTime: TimeInterval?
    private var ticker: Timer?
    private var lastTick = CACurrentMediaTime()
    private var generation = 0

    // MARK: Sounds (synthesised at launch)

    private let rattle = SoundFactory.rattleLoop()
    private let knock = SoundFactory.knock()
    private let whistle = SoundFactory.whistle()
    private let chime = SoundFactory.chime()
    private let kick = SoundFactory.kick()
    private let thud = SoundFactory.thud()
    private let swoosh = SoundFactory.swoosh()
    private let cheer = SoundFactory.cheer()
    private var voyCall = SoundFactory.shout(pitch: 170)
    private var guideCall = SoundFactory.shout(pitch: 230)
    private var voicesBaked = false

    // MARK: Drill state

    private var ballActive = false
    private var ballAtFeet = false
    private var ballBearing = 0.0
    private var ballDistance = 3.5
    private var ballDrift = 0.0
    private var awaitingTrap = false

    private var defenderActive = false
    private var defenderBearing = 0.0       // relative: the defender comes at *you*
    private var defenderDistance = 9.0
    private var awaitingDodge = false
    private var heardCall = false
    private var voyWait = 0.0
    private var untilNextCall = 0.0

    private var guideActive = false
    private var goalBearing = 0.0
    private var guideOffset = 0.0           // −1 left post, 0 centre, 1 right post
    private var guideStepIndex = 0
    private var untilGuideStep = 0.0
    private var awaitingShot = false
    private var insideGoalWindow = false
    private var shotInFlight = false
    private var shotProgress = 0.0
    private var shotError = 0.0

    init() {
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    // MARK: - Navigation

    func begin() {
        audio.start()
        bakeVoices()
        audio.playInterface(whistle)
        UIApplication.shared.isIdleTimerDisabled = true
        stage = .story
    }

    func showIntro(_ drill: Drill) {
        stopDrill()
        stage = .intro(drill)
        narrator.say(drill.spokenIntro)
    }

    func startDrill(_ drill: Drill) {
        stopDrill()
        narrator.stop()
        stage = .play(drill)
        round = 0
        updateMotion()
        audio.playInterface(whistle)
        after(0.8) { [weak self] in self?.nextRound(drill) }
    }

    func skip() {
        switch stage {
        case .intro(let drill): startDrill(drill)
        case .play(let drill): finish(drill)
        default: break
        }
    }

    func skipDrill(_ drill: Drill) {
        narrator.stop()
        finish(drill)
    }

    func playAgain() {
        trapTries = 0; trapped = 0; dodged = 0; goals = 0
        showIntro(.locate)
    }

    func goHome() {
        stopDrill()
        narrator.stop()
        stage = .welcome
        updateMotion()
    }

    func speak(_ text: String) {
        narrator.say(text)
    }

    // MARK: - Input

    /// Turn on the spot. Positive = clockwise (to your right).
    func turn(by degrees: Double) {
        guard case .play(let drill) = stage, drill != .voy else { return }
        heading = (heading + degrees).truncatingRemainder(dividingBy: 360)
        if heading < 0 { heading += 360 }
        refresh()
    }

    /// Tap / double-tap / space bar.
    func primaryAction() {
        guard case .play(let drill) = stage else { return }
        switch drill {
        case .locate: trap()
        case .shoot: shoot()
        case .voy:
            if awaitingDodge { say("Swipe left or right — away from the voice.") }
        }
    }

    /// −1 = dodge left, +1 = dodge right.
    func dodge(_ direction: Double) {
        guard case .play(.voy) = stage, awaitingDodge else { return }
        guard heardCall else {
            haptics.tap(intensity: 0.3, sharpness: 0.2)
            say("Not yet. Wait for the call.")
            return
        }
        awaitingDodge = false
        let side = sideWord(defenderBearing)
        if direction * defenderBearing < 0 {
            dodged += 1
            audio.playInterface(swoosh)
            haptics.tap(intensity: 0.9, sharpness: 0.9)
            pulse = Pulse(good: true)
            say("You slipped past! The call came from your \(side).")
        } else {
            audio.playInterface(thud)
            haptics.tap(intensity: 1, sharpness: 0.1)
            pulse = Pulse(good: false)
            say("Tackled. The call came from your \(side). Move away from the voice.")
        }
        after(0.5) { [weak self] in
            self?.defenderActive = false
            self?.audio.silence(.defender)
            self?.refresh()
        }
        after(2.2) { [weak self] in self?.nextRound(.voy) }
    }

    // MARK: - Rounds

    private func nextRound(_ drill: Drill) {
        guard round < Self.rounds else {
            finish(drill)
            return
        }
        round += 1
        soundCaption = ""
        switch drill {
        case .locate: startLocateRound()
        case .voy: startVoyRound()
        case .shoot: startShotRound()
        }
    }

    private func finish(_ drill: Drill) {
        stopDrill()
        if let next = drill.next {
            showIntro(next)
        } else {
            stage = .finale
            updateMotion()
            UIApplication.shared.isIdleTimerDisabled = false
            narrator.say(summary)
        }
    }

    var summary: String {
        "Full time. You trapped \(trapped) of \(Self.rounds) balls, beat \(dodged) of \(Self.rounds) defenders, and scored \(goals) of \(Self.rounds) shots — all without looking."
    }

    // MARK: Drill 1 — Find the ball

    private func startLocateRound() {
        let side: Double = Bool.random() ? 1 : -1
        ballBearing = heading + side * Double.random(in: 70...160)
        ballDistance = 3.5
        ballAtFeet = false
        ballActive = true
        // On the final ball it keeps rolling, like it would in a match.
        ballDrift = round == Self.rounds ? side * 7 : 0
        awaitingTrap = true
        audio.setVolume(.ball, 1)
        audio.loop(.ball, rattle)
        haptics.startHum()
        say(round == Self.rounds ? "Last ball. This one is still rolling." : "Ball \(round). Find the rattle.")
        refresh()
    }

    private func trap() {
        guard awaitingTrap else { return }
        trapTries += 1
        let error = wrap(ballBearing - heading)
        if abs(error) <= 15 {
            awaitingTrap = false
            trapped += 1
            ballActive = false
            audio.silence(.ball)
            audio.playInterface(chime)
            haptics.stopHum()
            haptics.tap(intensity: 1, sharpness: 0.8)
            pulse = Pulse(good: true)
            say(["Trapped it!", "Got it — nice touch.", "Under control!"][(round - 1) % 3])
            refresh()
            after(1.6) { [weak self] in self?.nextRound(.locate) }
        } else {
            haptics.tap(intensity: 0.4, sharpness: 0.2)
            pulse = Pulse(good: false)
            say(abs(error) > 120 ? "It's behind you." : "Not quite. It's to your \(sideWord(error)).")
        }
    }

    // MARK: Drill 2 — Voy!

    private func startVoyRound() {
        let side: Double = Bool.random() ? 1 : -1
        defenderBearing = side * Double.random(in: 50...100)
        defenderDistance = 9
        defenderActive = true
        heardCall = false
        awaitingDodge = true
        voyWait = Double.random(in: 1.2...2.6)  // you never know when they'll come
        untilNextCall = 0
        ballAtFeet = true
        ballDistance = 0.8
        ballActive = true
        audio.setVolume(.ball, 0.45)
        audio.loop(.ball, rattle)
        say("Defender \(round). Keep dribbling and listen.")
        refresh()
    }

    private func tickVoy(_ dt: Double) {
        guard awaitingDodge else { return }
        if voyWait > 0 {
            voyWait -= dt
            return
        }
        defenderDistance -= 2.3 * dt
        untilNextCall -= dt
        if untilNextCall <= 0 {
            audio.play(.defender, voyCall)
            heardCall = true
            calls += 1
            untilNextCall = 0.8
            soundCaption = "“Voy!” — from your \(sideWord(defenderBearing))"
        }
        if defenderDistance <= 1 {
            awaitingDodge = false
            audio.playInterface(thud)
            haptics.tap(intensity: 1, sharpness: 0.1)
            pulse = Pulse(good: false)
            say("Too slow — they reached you. Move as soon as you hear “Voy”.")
            after(0.5) { [weak self] in
                self?.defenderActive = false
                self?.audio.silence(.defender)
                self?.refresh()
            }
            after(2.2) { [weak self] in self?.nextRound(.voy) }
        }
        refresh()
    }

    // MARK: Drill 3 — Listen and shoot

    private func startShotRound() {
        let side: Double = Bool.random() ? 1 : -1
        goalBearing = heading + side * Double.random(in: 35...80)
        ballActive = false
        audio.silence(.ball)
        audio.setVolume(.ball, 1)
        guideActive = true
        guideStepIndex = 0
        untilGuideStep = 0.6
        insideGoalWindow = false
        awaitingShot = true
        haptics.stopHum()
        say("Shot \(round). Find the guide.")
        refresh()
    }

    private func tickShoot(_ dt: Double) {
        if awaitingShot {
            untilGuideStep -= dt
            if untilGuideStep <= 0 { guideStep() }
        }
        if shotInFlight {
            shotProgress += dt / 0.7
            ballDistance = 0.6 + 8.4 * min(1, shotProgress)
            refresh()
            if shotProgress >= 1 {
                shotInFlight = false
                resolveShot()
            }
        }
    }

    private func guideStep() {
        // Knock left post, knock right post, call from the centre. Repeat.
        let pattern: [(offset: Double, wait: Double)] = [(-1, 0.35), (1, 0.6), (0, 1.5)]
        let step = pattern[guideStepIndex % pattern.count]
        guideStepIndex += 1
        guideOffset = step.offset
        refresh()
        if step.offset == 0 {
            audio.play(.guide, guideCall)
            soundCaption = "Guide: “Here!” — \(directionPhrase(wrap(goalBearing - heading)))"
        } else {
            audio.play(.guide, knock)
            soundCaption = "Knock on the \(step.offset < 0 ? "left" : "right") post"
        }
        untilGuideStep = step.wait
    }

    private func shoot() {
        guard awaitingShot else { return }
        awaitingShot = false
        guideActive = false
        audio.silence(.guide)
        shotError = wrap(goalBearing - heading)   // + means the goal was to your right
        ballBearing = heading
        ballAtFeet = false
        ballDistance = 0.6
        ballActive = true
        audio.loop(.ball, rattle)
        audio.playInterface(kick)
        haptics.tap(intensity: 1, sharpness: 0.5)
        shotProgress = 0
        shotInFlight = true
        soundCaption = ""
        refresh()
    }

    private func resolveShot() {
        ballActive = false
        audio.silence(.ball)
        let miss = abs(shotError)
        if miss <= Self.goalHalfAngle {
            goals += 1
            audio.playInterface(cheer)
            haptics.celebrate()
            pulse = Pulse(good: true)
            say("GOAL! Listen — the crowd waits in silence, then erupts.")
        } else if miss <= Self.goalHalfAngle + 3 {
            audio.playInterface(knock)
            haptics.tap(intensity: 0.8, sharpness: 1)
            pulse = Pulse(good: false)
            say("Off the post! So close.")
        } else {
            audio.playInterface(thud)
            haptics.tap(intensity: 0.5, sharpness: 0.1)
            pulse = Pulse(good: false)
            say("Wide. The goal was to your \(sideWord(shotError)).")
        }
        refresh()
        after(2.8) { [weak self] in self?.nextRound(.shoot) }
    }

    // MARK: - Every frame

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(0.1, now - lastTick)
        lastTick = now
        guard case .play(let drill) = stage else { return }
        switch drill {
        case .locate:
            if awaitingTrap && ballDrift != 0 {
                ballBearing += ballDrift * dt
                refresh()
            }
        case .voy:
            tickVoy(dt)
        case .shoot:
            tickShoot(dt)
        }
    }

    /// Re-positions every sound relative to where you're facing and updates
    /// the haptic hum, visual glow and radar.
    private func refresh() {
        var next: [Marker] = []

        if ballActive {
            if ballAtFeet { ballBearing = heading }
            let bearing = wrap(ballBearing - heading)
            audio.place(.ball, bearing: bearing, distance: ballDistance)
            next.append(Marker(id: "ball", kind: .ball, bearing: bearing, distance: ballDistance))
        }
        if defenderActive {
            audio.place(.defender, bearing: defenderBearing, distance: defenderDistance)
            next.append(Marker(id: "defender", kind: .defender, bearing: defenderBearing, distance: defenderDistance))
        }
        if guideActive {
            let goal = wrap(goalBearing - heading)
            let source = wrap(goalBearing + guideOffset * Self.goalHalfAngle - heading)
            audio.place(.guide, bearing: source, distance: Self.guideDistance)
            next.append(Marker(id: "goal", kind: .goal, bearing: goal, distance: Self.guideDistance))
            next.append(Marker(id: "guide", kind: .guide, bearing: source, distance: Self.guideDistance + 0.8))
        }
        markers = next

        if awaitingTrap {
            let a = closeness(wrap(ballBearing - heading))
            alignment = a
            haptics.setHum(a * a)
        } else if awaitingShot {
            let goal = wrap(goalBearing - heading)
            alignment = closeness(goal)
            let inside = abs(goal) <= Self.goalHalfAngle
            if inside && !insideGoalWindow { haptics.tap(intensity: 0.6, sharpness: 1) }
            insideGoalWindow = inside
        } else {
            alignment = 0
        }
    }

    // MARK: - Helpers

    private func stopDrill() {
        generation += 1
        awaitingTrap = false
        awaitingDodge = false
        awaitingShot = false
        shotInFlight = false
        ballActive = false
        defenderActive = false
        guideActive = false
        audio.silenceAll()
        haptics.stopHum()
        markers = []
        alignment = 0
        soundCaption = ""
        status = ""
    }

    private func say(_ text: String) {
        status = text
        narrator.say(text)
    }

    /// Runs `work` later, unless the drill has changed in the meantime.
    private func after(_ seconds: Double, _ work: @escaping () -> Void) {
        let token = generation
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.generation == token else { return }
                work()
            }
        }
    }

    private func closeness(_ bearing: Double) -> Double {
        max(0, 1 - abs(bearing) / 150)
    }

    private func sideWord(_ bearing: Double) -> String {
        bearing < 0 ? "left" : "right"
    }

    private func directionPhrase(_ bearing: Double) -> String {
        if abs(bearing) <= Self.goalHalfAngle { return "dead ahead" }
        if abs(bearing) > 135 { return "behind you" }
        return "to your \(sideWord(bearing))"
    }

    private func bakeVoices() {
        guard !voicesBaked else { return }
        voicesBaked = true
        baker.bake("Voy!", pitch: 0.75, rate: 0.55) { [weak self] buffer in
            MainActor.assumeIsolated { if let buffer { self?.voyCall = buffer } }
        }
        baker.bake("Here!", pitch: 1.3, rate: 0.5) { [weak self] buffer in
            MainActor.assumeIsolated { if let buffer { self?.guideCall = buffer } }
        }
    }

    // MARK: Motion

    /// Turning the device turns you. We integrate the rotation rate around
    /// the gravity axis, so it works however the device is held — flat,
    /// upright or tilted — and with no permission prompt.
    private func updateMotion() {
        let playing: Bool
        if case .play = stage { playing = true } else { playing = false }
        if playing && turnWithDevice && motion.isDeviceMotionAvailable {
            guard !motion.isDeviceMotionActive else { return }
            lastMotionTime = nil
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let data else { return }
                let g = data.gravity
                let r = data.rotationRate
                let clockwise = r.x * g.x + r.y * g.y + r.z * g.z   // rad/s about vertical
                let timestamp = data.timestamp
                MainActor.assumeIsolated {
                    guard let self else { return }
                    defer { self.lastMotionTime = timestamp }
                    guard let last = self.lastMotionTime else { return }
                    let dt = min(0.1, timestamp - last)
                    let degrees = clockwise * dt * 180 / .pi
                    if abs(degrees) > 0.01 { self.turn(by: degrees) }
                }
            }
        } else {
            motion.stopDeviceMotionUpdates()
        }
    }
}
