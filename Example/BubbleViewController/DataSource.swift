//
//  DataSource.swift
//  BubbleViewController
//
//  Created by Nick Walker on 5/10/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import BubbleViewController

class DataSource: BubblesViewDataSource {
    private let colors = [UIColor.blueColor(), .greenColor(), .redColor(), .magentaColor(), .cyanColor(), .orangeColor()]
    var focused = 0
    func focusedBubble() -> Int {
        return focused
    }
    
    func relatedForBubble(bubble: Int) -> Set<Int> {
        var related = [0,1,2,3,4,5]
        related.removeAtIndex(bubble)
        related.removeAtIndex(max(bubble - 1, 0))
        return Set(related)
    }

    func configureBubble(index: Int) -> BubbleView {
        let view = BubbleView()
        view.label.text = "\(index)"
        view.backgroundColor = colors[index]
        return view
    }
}