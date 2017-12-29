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
import HSLuvSwift

class HueSpaceDataSource: BubblesViewDataSource {
    // Indices will be into an imaginary array of size sum 8]6^k for k in 0...h
    var focused: Int
    let inOrderMapping: [Int]
    let tree: CompleteKaryTree
    init(levels: Int, divisions: Int) {

        tree = CompleteKaryTree(children: divisions, height: levels)
        var temp = [Int](repeating: -1, count: tree.size)
        let inOrder = tree.generateInOrderTraversal()
        for i in 0..<inOrder.count {
            temp[inOrder[i]] = i
        }
        inOrderMapping = temp
        focused = tree.root
    }

    func focusedBubble() -> Int {
        return focused
    }

    // This is a tree, so the related are children
    func relatedForBubble(_ index: Int) -> Set<Int> {
        guard !tree.isLeaf(index) else {
            return Set()
        }
        return Set(tree.children(index))

    }

    func configureBubble(_ index: Int) -> BubbleView {
        let view = BubbleView()
        let position = inOrderMapping[index]
        let normalizedPosition = Double(position) / Double(tree.size)
        let offsetPosition = applyOffset(normalizedPosition)
        if index == 0 {
            view.backgroundColor = .white
        } else {
            view.backgroundColor = colorForPosition(offsetPosition)
        }

        if index != 0 {
            let hueDegrees = abs(round(offsetPosition * 360.0))
            let hueString = String(format: "%.0f", hueDegrees)
            view.label.text = "\(hueString)°"
        }
        return view
    }

    fileprivate func applyOffset(_ position: Double) -> Double {
        let shifted = position + (30.61 / 360.0)
        return shifted > 1.0 ? 1.0 - shifted: shifted
    }

    fileprivate func colorForPosition(_ position: Double) -> UIColor {
        return UIColor(hue: position * 360.0, saturation: 100.0, lightness: 60.0, alpha: 1.0)
    }

    func shouldAllowFocus(_ index: Int) -> Bool {
        return !tree.isLeaf(index)
    }

 }


public func pow(_ base: Int, _ exponent: Int) -> Int {
    return Int(pow(Float(base), Float(exponent)))
}
