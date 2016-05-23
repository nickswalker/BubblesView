import UIKit
import XCTest
@testable import BubblesView

class Tests: XCTestCase {
    
    func testPositionClockWrapsAround() {
        var clock = PositionClock(divisions: 10, radius: 1)
        var results = [CGPoint]()
        for _ in 0..<10 {
            results.append(clock.advance(withCenter: CGPointZero))
        }
        for i in 0..<10 {
            XCTAssertEqual(results[i], clock.advance(withCenter: CGPointZero))
        }
    }

    func testPositionClockPointsAreCorrect() {
        var clock = PositionClock(divisions: 4, radius: 1)
        var results = [CGPoint]()
        for _ in 0..<4 {
            results.append(clock.advance(withCenter: CGPointZero))
        }
        for i in 0..<4 {
            XCTAssertTrue(0.99...1.01 ~= abs(results[i].x + results[i].y))
        }
    }

    
}
