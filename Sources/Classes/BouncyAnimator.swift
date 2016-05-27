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
import CoreMotion

/// Presents related bubbles as being attached by a rod to a central focused bubble.
/// The bubbles do not rotate about their own center, but related bubbles can freely move about the focused,
/// and can collide with eachother. The views are springy and playful to interact with.
/// Uses UIDynamicAnimator to provide animation.
public class BouncyAnimator: BubblesViewAnimator {
    public weak var view: BubblesView!

    /// If true, the view will use the acceloremeter to apply a small force to bubbles to simulate
    /// gravity in the direction of gravity relative to the device.
    public var gravityEffect: Bool = false {
        didSet(oldValue) {
            if gravityEffect {
                animator.addBehavior(gravityBehavior)
                // We need a weak self to avoid creating a retain cycle between self and the motion manager
                motionManager.startDeviceMotionUpdatesToQueue(motionQueue) { [weak self] motion, error in
                    self?.motionUpdate(motion, error: error)
                }
            } else {
                motionManager.stopDeviceMotionUpdates()
                animator.removeBehavior(gravityBehavior)
            }
        }
    }


    private var focusedSnap: UISnapBehavior?

    private var bubbleBehaviors = [BubbleView: BubbleBehavior]()
    private var relatedAttachments = [BubbleView: UIAttachmentBehavior]()
    private var collisionBehavior = UICollisionBehavior()
    private var animator: UIDynamicAnimator!

    private var gravityBehavior = UIGravityBehavior()
    private lazy var motionManager = CMMotionManager()
    private lazy var motionQueue = NSOperationQueue()

    // MARK: Initialization

    public init() {
    }

    public func configureForView(view: BubblesView) {
        self.view = view
        animator = UIDynamicAnimator(referenceView: view)
        collisionBehavior.collisionMode = .Everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = false
        animator.addBehavior(collisionBehavior)
        //animator.setValue(true, forKey: "debugEnabled")
    }

    // MARK: Behaviors

    public func addBehaviors(bubble: BubbleView){
        let bubbleBehavior = BubbleBehavior(item: bubble)
        gravityBehavior.addItem(bubble)
        bubbleBehaviors[bubble] = bubbleBehavior
        animator.addBehavior(bubbleBehavior)
        collisionBehavior.addItem(bubble)
    }

    public func removeBehaviors(bubble: BubbleView) {
        gravityBehavior.removeItem(bubble)
        if let behavior = bubbleBehaviors[bubble] {
            animator.removeBehavior(behavior)
        }
        bubbleBehaviors.removeValueForKey(bubble)
        collisionBehavior.removeItem(bubble)
    }

    public func addVelocity(bubble: BubbleView, velocity: CGVector) {
        if let behavior = bubbleBehaviors[bubble] {
            behavior.addLinearVelocity(CGPoint(x: velocity.dx, y: velocity.dy))
        }
    }


    // MARK: Related

    public func addRelatedBehaviors(bubble: BubbleView) {
        assert(view.focusedBubble != nil)
        let attachment = UIAttachmentBehavior(item: bubble, attachedToItem: view.focusedBubble!)
        attachment.length = 120
        relatedAttachments[bubble] = attachment
        animator.addBehavior(attachment)
        collisionBehavior.addItem(bubble)
    }

    public func removeRelatedBehaviors(bubble: BubbleView) {
        guard let attachment = relatedAttachments.removeValueForKey(bubble) else {
            print("No attachment for \(bubble.index)")
            return
        }
        animator.removeBehavior(attachment)
    }

    // MARK: Focus

    public func addFocusedBehaviors(bubble: BubbleView) {
        assert(bubble.index != nil)
        let newSnap = UISnapBehavior(item: bubble, snapToPoint: self.view.center)
        newSnap.damping = 0.1
        UIView.animateWithDuration(0.3) {
            bubble.center = self.view.center
        }
        animator.addBehavior(newSnap)
        focusedSnap = newSnap
    }

    public func removeFocusedBehaviors(bubble: BubbleView) {
        // Remove the old bubble
        if let snap = focusedSnap {
            animator.removeBehavior(snap)
        }

        focusedSnap = nil
    }

    // MARK: Device Motion

    /**
     The callback that receives new accelerometer information.

     - parameter motion: motion data
     - parameter error:
     */
    internal func motionUpdate(motion: CMDeviceMotion?, error: NSError?) {
        guard let motion = motion where error == nil else {
            return
        }

        let grav = motion.gravity
        let x = CGFloat(grav.x)
        let y = CGFloat(grav.y)
        var v = CGVector(dx: x, dy: -y)
        dispatch_sync(dispatch_get_main_queue()) {
            self.gravityBehavior.gravityDirection = v
            self.gravityBehavior.magnitude = 0.2
        }
    }

    // MARK: Events

    public func layoutChanged() {
        if let focused = view.focusedBubble {
            // Snap the bubble to the new center
            focusedSnap?.snapPoint = view.center
        }
    }
}