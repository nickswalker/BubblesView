//
//  ViewController.swift
//  BubbleViewController
//
//  Created by Nicholas Walker on 05/09/2016.
//  Copyright (c) 2016 Nicholas Walker. All rights reserved.
//

import UIKit
import BubblesView

class ViewController: BubblesViewController {
    let colorDataSource = BubblesViewHueSpaceDataSource(levels: 3, divisions: 6)
    var path = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bubblesView.dataSource = colorDataSource
        bubblesView.delegate = self
        bubblesView.reloadData()
        //bubblesView.gravityEffect = true
        bubblesView.backgroundColor = .clearColor()
        view.backgroundColor = .blackColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}


extension ViewController: BubblesViewDelegate {
    func didSelectBubble(bubble: Int) {
        guard colorDataSource.shouldAllowFocus(bubble) else {
            return
        }
        if bubble == colorDataSource.focused && path.count > 0{
            let prev = path.removeLast()
            colorDataSource.focused = prev
            bubblesView.focus(index: prev)
        } else if bubble != colorDataSource.focused {
            path.append(colorDataSource.focused)
            colorDataSource.focused = bubble
            bubblesView.focus(index: bubble)
        }
    }
}
