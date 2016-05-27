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

public protocol BubblesViewAnimator {
    weak var view: BubblesView! { get }

    func configureForView(view: BubblesView)

    func addBehaviors(bubble: BubbleView)
    func removeBehaviors(bubble: BubbleView)

    func addRelatedBehaviors(bubble: BubbleView)
    func removeRelatedBehaviors(bubble: BubbleView)

    func addFocusedBehaviors(bubble: BubbleView)
    func removeFocusedBehaviors(bubble: BubbleView)

    func addVelocity(bubble: BubbleView, velocity: CGVector)

    func layoutChanged()
}

extension BubblesViewAnimator {
    // MARK: Animation Helpers

    func animateRemoveSubview(view: UIView) {
        // The view shouldn't cover anything as it leaves
        self.view.sendSubviewToBack(view)
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            view.transform = CGAffineTransformMakeScale(0.1, 0.1)
        }) { (_) in
            view.removeFromSuperview()
        }
    }

    /**
     Useful for animating in new subviews

     - parameter view: <#view description#>
     */
    func animateToNormalSize(view: UIView) {
        animateToScale(view, scale: 1.0)
    }

    private func animateGrow(view: UIView) {
        animateToScale(view, scale: 1.2)
    }

    private func animateToScale(view: UIView, scale: CGFloat) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            view.transform = CGAffineTransformMakeScale(scale, scale)
        }) { (_) in
            view.transform = CGAffineTransformMakeScale(scale, scale)
        }
    }
}