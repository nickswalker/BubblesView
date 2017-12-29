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
open class BouncyAnimator: BubblesViewAnimator {
    open weak var view: BubblesView!

    /// If true, the view will use the acceloremeter to apply a small force to bubbles to simulate
    /// gravity in the direction of gravity relative to the device.
    open var gravityEffect: Bool = false {
        didSet(oldValue) {
            if gravityEffect {
                animator.addBehavior(gravityBehavior)
                // We need a weak self to avoid creating a retain cycle between self and the motion manager
                motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] (motion, error) in
                    self?.motionUpdate(motion, error: error)
                }
            } else {
                motionManager.stopDeviceMotionUpdates()
                animator.removeBehavior(gravityBehavior)
            }
        }
    }


    fileprivate var focusedSnap: UISnapBehavior?

    fileprivate var bubbleBehaviors = [BubbleView: BubbleBehavior]()
    fileprivate var relatedAttachments = [BubbleView: UIAttachmentBehavior]()
    fileprivate var collisionBehavior = UICollisionBehavior()
    fileprivate var animator: UIDynamicAnimator!

    fileprivate var gravityBehavior = UIGravityBehavior()
    fileprivate lazy var motionManager = CMMotionManager()
    fileprivate lazy var motionQueue = OperationQueue()

    // MARK: Initialization

    public init() {
    }

    open func configureForView(_ view: BubblesView) {
        self.view = view
        animator = UIDynamicAnimator(referenceView: view)
        collisionBehavior.collisionMode = .everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = false
        animator.addBehavior(collisionBehavior)
        //animator.setValue(true, forKey: "debugEnabled")
    }

    // MARK: Behaviors

    open func addBehaviors(_ bubble: BubbleView){
        let bubbleBehavior = BubbleBehavior(item: bubble)
        gravityBehavior.addItem(bubble)
        bubbleBehaviors[bubble] = bubbleBehavior
        animator.addBehavior(bubbleBehavior)
        collisionBehavior.addItem(bubble)
    }

    open func removeBehaviors(_ bubble: BubbleView) {
        gravityBehavior.removeItem(bubble)
        if let behavior = bubbleBehaviors[bubble] {
            animator.removeBehavior(behavior)
        }
        bubbleBehaviors.removeValue(forKey: bubble)
        collisionBehavior.removeItem(bubble)
    }

    open func addVelocity(_ bubble: BubbleView, velocity: CGVector) {
        if let behavior = bubbleBehaviors[bubble] {
            behavior.addLinearVelocity(CGPoint(x: velocity.dx, y: velocity.dy))
        }
    }


    // MARK: Related

    open func addRelatedBehaviors(_ bubble: BubbleView) {
        assert(view.focusedBubble != nil)
        let attachment = UIAttachmentBehavior(item: bubble, attachedTo: view.focusedBubble!)
        attachment.length = 120
        relatedAttachments[bubble] = attachment
        animator.addBehavior(attachment)
        collisionBehavior.addItem(bubble)
    }

    open func removeRelatedBehaviors(_ bubble: BubbleView) {
        guard let attachment = relatedAttachments.removeValue(forKey: bubble) else {
            print("No attachment for \(String(describing: bubble.index))")
            return
        }
        animator.removeBehavior(attachment)
    }

    // MARK: Focus

    open func addFocusedBehaviors(_ bubble: BubbleView) {
        assert(bubble.index != nil)
        let newSnap = UISnapBehavior(item: bubble, snapTo: self.view.center)
        newSnap.damping = 0.1
        UIView.animate(withDuration: 0.3, animations: {
            bubble.center = self.view.center
        }) 
        animator.addBehavior(newSnap)
        focusedSnap = newSnap
    }

    open func removeFocusedBehaviors(_ bubble: BubbleView) {
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
    internal func motionUpdate(_ motion: CMDeviceMotion?, error: Error?) {
        guard let motion = motion, error == nil else {
            return
        }

        let grav = motion.gravity
        let x = CGFloat(grav.x)
        let y = CGFloat(grav.y)
        let v = CGVector(dx: x, dy: -y)
        DispatchQueue.main.sync {
            self.gravityBehavior.gravityDirection = v
            self.gravityBehavior.magnitude = 0.2
        }
    }

    // MARK: Events

    open func layoutChanged() {
        if view.focusedBubble != nil {
            // Snap the bubble to the new center
            focusedSnap?.snapPoint = view.center
        }
    }
}
