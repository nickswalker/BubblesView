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

/// The interface that should be provided by the object that manages animations for a BubbleView
public protocol BubblesViewAnimator {
    /// The view that this animator is animating the contents of
    weak var view: BubblesView! { get }

    /**
     Configures the animator for a new BubblesView

     - parameter view: the view which the animator will manage
     */
    func configureForView(_ view: BubblesView)

    /**
     Defines how a certain view should behave in the animation system. Called
     when a bubble should enter the animation system

     - parameter bubble: the bubble entering the animation system
     */
    func addBehaviors(_ bubble: BubbleView)

    /**
     Removes a view from the animation system. If the bubble was related or focused, the BubblesView
     will have called the appropriate methods to remove these behaviors before calling this method.

     - parameter bubble: the bubble to remove from the animation system
     */
    func removeBehaviors(_ bubble: BubbleView)

    /**
     Defines the behaviors for a bubble that is related to the current focused view.
     Called once the focused view has been configured. A bubble that is related will not become
     focused without first having `removeRelatedBehaviors` called.

     - parameter bubble: the bubble that is related to the focused view
     */
    func addRelatedBehaviors(_ bubble: BubbleView)

    /**
     Removes the behaviors for a bubble that is related to the current focused view.

     - parameter bubble: the bubble that is related to the focused view
     */
    func removeRelatedBehaviors(_ bubble: BubbleView)

    /**
     Defines the behaviors for the focused bubble. The focused bubble is guaranteed not to be
     one of the currently "related" bubbles.

     - parameter bubble: the focused bubble
     */
    func addFocusedBehaviors(_ bubble: BubbleView)

    /**
     Removes the behaviors of the focused bubble.

     - parameter bubble: the focused bubble
     */
    func removeFocusedBehaviors(_ bubble: BubbleView)

    /**
     Suggests that the animator add velocity to a particular bubble under its management

     - parameter bubble:   the bubble that should be animated
     - parameter velocity: the velocity vector that should be added
     */
    func addVelocity(_ bubble: BubbleView, velocity: CGVector)

    /**
     Called to notify the animation system that the frame of the view it is 
     animating has changed.
     */
    func layoutChanged()
}

extension BubblesViewAnimator {
    // MARK: Animation Helpers

    func animateRemoveSubview(_ view: UIView) {
        // The view shouldn't cover anything as it leaves
        self.view.sendSubview(toBack: view)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { (_) in
            view.removeFromSuperview()
        }
    }

    /**
     Animates the view's current transform to the identity. Useful for animating-in new subviews

     - parameter view: the view to animate
     */
    func animateToNormalSize(_ view: UIView) {
        animateToScale(view, scale: 1.0)
    }

    fileprivate func animateGrow(_ view: UIView) {
        animateToScale(view, scale: 1.2)
    }

    fileprivate func animateToScale(_ view: UIView, scale: CGFloat) {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { (_) in
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
}
