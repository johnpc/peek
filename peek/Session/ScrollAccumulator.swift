import CoreGraphics

/// Turns continuous two-finger pan distance into discrete wheel steps, the
/// way a VNC server expects them.
struct ScrollAccumulator: Equatable {
    /// Points of finger travel per wheel step.
    var pointsPerStep: CGFloat = 24

    private var carryX: CGFloat = 0
    private var carryY: CGFloat = 0

    /// Feed a translation delta; returns whole steps to send (may be zero).
    /// Dragging fingers up scrolls down (natural scrolling), hence the sign flip.
    mutating func add(_ delta: CGSize) -> (dx: Int, dy: Int) {
        carryX -= delta.width
        carryY -= delta.height
        let stepsX = Int((carryX / pointsPerStep).rounded(.towardZero))
        let stepsY = Int((carryY / pointsPerStep).rounded(.towardZero))
        carryX -= CGFloat(stepsX) * pointsPerStep
        carryY -= CGFloat(stepsY) * pointsPerStep
        return (stepsX, stepsY)
    }

    mutating func reset() {
        carryX = 0
        carryY = 0
    }
}
