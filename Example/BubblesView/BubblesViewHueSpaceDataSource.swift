//
//  DataSource.swift
//  BubbleViewController
//
//  Created by Nick Walker on 5/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import BubblesView
import HUSLSwift

class BubblesViewHueSpaceDataSource: BubblesViewDataSource {
    // Indices will be into an imaginary array of size sum 8]6^k for k in 0...h
    var focused: Int
    let inOrderMapping: [Int]
    let tree: CompleteKaryTree
    init(levels: Int, divisions: Int) {

        tree = CompleteKaryTree(children: divisions, height: levels)
        var temp = [Int](count: tree.size, repeatedValue: -1)
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
    func relatedForBubble(index: Int) -> Set<Int> {
        guard !tree.isLeaf(index) else {
            return Set()
        }
        return Set(tree.children(index))

    }

    func configureBubble(index: Int) -> BubbleView {
        let view = BubbleView()
        let position = inOrderMapping[index]
        let normalizedPosition = Double(position) / Double(tree.size)
        let offsetPosition = applyOffset(normalizedPosition)
        if index == 0 {
            view.backgroundColor = .whiteColor()
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

    private func applyOffset(position: Double) -> Double {
        let shifted = position + (30.61 / 360.0)
        return shifted > 1.0 ? 1.0 - shifted: shifted
    }

    private func colorForPosition(position: Double) -> UIColor {
        return UIColor(hue: position * 360.0, saturation: 100.0, lightness: 60.0, alpha: 1.0)
    }

    func shouldAllowFocus(index: Int) -> Bool {
        return !tree.isLeaf(index)
    }

 }


public func pow(_ base: Int, _ exponent: Int) -> Int {
    return Int(pow(Float(base), Float(exponent)))
}
