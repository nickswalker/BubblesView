//
//  DataSource.swift
//  BubbleViewController
//
//  Created by Nick Walker on 5/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import BubblesView
//

class BubblesViewHueSpaceDataSource: BubblesViewDataSource {
    // Indices will be into an imaginary array of size 8^h
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
        view.backgroundColor = colorForPosition(position)
        return view
    }

    // Maps the color wheel onto 0..<2^k + 1
    // There are 255^3 colors, 

    private func colorForPosition(position: Int) -> UIColor {
        if position == tree.size / 2 {
            return .grayColor()
        }
        let normalized = CGFloat(position) / CGFloat(tree.size)
        return UIColor(hue: normalized, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }

    func shouldAllowFocus(index: Int) -> Bool {
        return !tree.isLeaf(index)
    }

 }


public func pow(_ base: Int, _ exponent: Int) -> Int {
    return Int(pow(Float(base), Float(exponent)))
}
