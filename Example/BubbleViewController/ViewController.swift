//
//  ViewController.swift
//  BubbleViewController
//
//  Created by Nicholas Walker on 05/09/2016.
//  Copyright (c) 2016 Nicholas Walker. All rights reserved.
//

import UIKit
import BubbleViewController

class ViewController: BubbleViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = DataSource()
        delegate = self
        reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension ViewController: BubbleViewDelegate {
    func didSelectBubble(bubble: Int) {
        
    }
}
