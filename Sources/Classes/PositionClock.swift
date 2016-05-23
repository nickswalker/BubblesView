struct PositionClock {
    private var index = 0
    private let divisions: Int
    private let radius: Int

    init(divisions: Int, radius: Int) {
        self.divisions = divisions
        self.radius = radius
    }

    mutating func advance(withCenter center: CGPoint) -> CGPoint {
        let arc =  (2.0 * M_PI) / Double(divisions)
        let vector = generateVector(Double(index) * arc, magnitude: Double(radius))
        let position = CGPoint(x: center.x + vector.dx, y: center.y + vector.dy)
        index += 1
        index %= divisions
        return position
    }

    private func generateVector(radians: Double, magnitude: Double) -> CGVector {
        let r = Double(radius)
        return CGVector(dx: r * cos(radians), dy: r * sin(radians))
    }
}