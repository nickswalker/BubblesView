//
//  Copyright (c) 2016 Nick Walker.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

/// A modular counter with helpers to output coordinates on a circle.
struct PositionClock {
    private var index = 0
    private let divisions: Int
    private let radius: Int

    init(divisions: Int, radius: Int) {
        self.divisions = divisions
        self.radius = radius
    }

    /**
     Place a new point along the circle defined by the radius and the given center. Advances
     the internal counter, so the next call will generate the next point along the circle.

     - parameter center: the center of the circle on which to generate the point

     - returns: the point on the circle
     */
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