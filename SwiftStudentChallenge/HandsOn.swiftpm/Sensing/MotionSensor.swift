import CoreMotion

/// Streams vertical acceleration from Core Motion.
///
/// `userAcceleration` already has gravity removed. Projecting it onto the
/// gravity direction gives acceleration straight up/down however the phone
/// is held — so it doesn't matter if it tilts in your hands. No permission
/// prompt is needed for device motion.
final class MotionSensor {
    private let manager = CMMotionManager()

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    /// - Parameter handler: (timestamp in seconds, upward acceleration in m/s²), on the main queue.
    func start(_ handler: @escaping (Double, Double) -> Void) {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 100.0
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let g = motion.gravity
            let a = motion.userAcceleration
            let length = max(0.0001, (g.x * g.x + g.y * g.y + g.z * g.z).squareRoot())
            // Gravity points down, so "up" is the negative of its direction. Units: g → m/s².
            let up = -(a.x * g.x + a.y * g.y + a.z * g.z) / length * 9.81
            handler(motion.timestamp, up)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
