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
import UIKit
import BubblesView

class ViewController: BubblesViewController {
    let colorDataSource = BubblesViewHueSpaceDataSource(levels: 3, divisions: 7)
    var path = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bubblesView.dataSource = colorDataSource
        bubblesView.delegate = self
        bubblesView.reloadData()
        let animator = BouncyAnimator()
        //animator.gravityEffect = true
        //bubblesView.allowsDraggingBubbles = false
        animator.configureForView(bubblesView)
        bubblesView.animator = animator
        bubblesView.backgroundColor = .clearColor()
        view.backgroundColor = .blackColor()
        bubblesView.reloadData()
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
