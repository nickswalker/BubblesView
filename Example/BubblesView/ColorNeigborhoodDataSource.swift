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
import Foundation
import BubblesView
import HUSLSwift

class BubblesViewHueSpaceDataSource: BubblesViewDataSource {
    // Indices will be into an imaginary array of size sum 8]6^k for k in 0...h
    var focused: Int = 50

    init(levels: Int, divisions: Int) {

    }

    func focusedBubble() -> Int {
        return focused
    }

    // This is a tree, so the related are children
    func relatedForBubble(index: Int) -> Set<Int> {
        var results = Set<Int>()
        for i in -4...3 where i != 0{
            let wrapped = { Void -> Int in
                var neighbor: Int = (index + i * 3) % 360
                neighbor = neighbor < 0 ? 360 + neighbor : neighbor
                return neighbor
            }()
            results.insert(wrapped)
        }

        return results

    }

    func configureBubble(index: Int) -> BubbleView {
        let view = BubbleView()
        view.backgroundColor = colorForPosition(index)
        let hueDegrees = Float(index)
        let hueString = String(format: "%.0f", hueDegrees)
        //view.label.text = "\(hueString)°"

        return view
    }

    private func colorForPosition(position: Int) -> UIColor {
        return UIColor(hue: Double(position), saturation: 100.0, lightness: 60.0, alpha: 1.0)
    }

    func shouldAllowFocus(index: Int) -> Bool {
        return true
    }

 }

