//
//  ViewController.swift
//  BubbleViewController
//
//  Created by Nicholas Walker on 05/09/2016.
//  Copyright (c) 2016 Nicholas Walker. All rights reserved.
//

import UIKit
import BubbleViewController

class ViewController: BubblesViewController {
    let numberSupplier = DataSource()
    var path = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bubblesView.dataSource = numberSupplier
        bubblesView.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension ViewController: BubblesViewDelegate {
    func didSelectBubble(bubble: Int) {
        if bubble == numberSupplier.focused && path.count > 0{
            let prev = path.removeLast()
            numberSupplier.focused = prev
            bubblesView.focus(prev)
        } else if bubble != numberSupplier.focused {
            path.append(numberSupplier.focused)
            numberSupplier.focused = bubble
            bubblesView.focus(bubble)
        }
    }
}
