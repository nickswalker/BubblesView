import Foundation
import CoreMotion

public class BubblesViewAnimator {
    private var animator: UIDynamicAnimator!
    private weak var view: BubblesView!

    private var focusedSnap: UISnapBehavior?

    private var bubbleBehaviors = [BubbleView: BubbleBehavior]()
    private var relatedAttachments = [BubbleView: UIAttachmentBehavior]()
    private var collisionBehavior = UICollisionBehavior()

    public var gravityEffect: Bool = false {
        didSet(oldValue) {
            if gravityEffect {
                animator.addBehavior(gravityBehavior)
                // we need a weak self to avoid creating a retain cycle between self and the motion manager
                motionManager.startDeviceMotionUpdatesToQueue(motionQueue) { [weak self] motion, error in
                    self?.motionUpdate(motion, error: error)
                }
            } else {
                motionManager.stopDeviceMotionUpdates()
                animator.removeBehavior(gravityBehavior)
            }
        }
    }

    private var gravityBehavior = UIGravityBehavior()
    private lazy var motionManager = CMMotionManager()
    private lazy var motionQueue = NSOperationQueue()

    // MARK: Initialization

    init(owner: BubblesView) {
        self.view = owner
        animator = UIDynamicAnimator(referenceView: view)
        collisionBehavior.collisionMode = .Everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = false
        animator.addBehavior(collisionBehavior)
        //animator.setValue(true, forKey: "debugEnabled")
    }

    // MARK: Behaviors
    
    func addBehaviors(bubble: BubbleView){
        let bubbleBehavior = BubbleBehavior(item: bubble)
        gravityBehavior.addItem(bubble)
        bubbleBehaviors[bubble] = bubbleBehavior
        animator.addBehavior(bubbleBehavior)
        collisionBehavior.addItem(bubble)
    }

    func removeBehaviors(bubble: BubbleView) {
        gravityBehavior.removeItem(bubble)
        animator.removeBehavior(bubbleBehaviors[bubble]!)
        bubbleBehaviors.removeValueForKey(bubble)
        collisionBehavior.removeItem(bubble)
    }

    func addAttachment(bubble: BubbleView) {
        assert(view.focusedBubble != nil)
        let attachment = UIAttachmentBehavior(item: bubble, attachedToItem: view.focusedBubble!)
        attachment.length = 120
        relatedAttachments[bubble] = attachment
        animator.addBehavior(attachment)
        collisionBehavior.addItem(bubble)
    }

    func removeAttachment(bubble: BubbleView) {
        let attachment = relatedAttachments.removeValueForKey(bubble)
        animator.removeBehavior(attachment!)
    }

    func addVelocity(bubble: BubbleView, velocity: CGVector) {
        if let behavior = bubbleBehaviors[bubble] {
            behavior.addLinearVelocity(CGPoint(x: velocity.dx, y: velocity.dy))
        }
    }

    // MARK: Focus

    func configureFocused(bubble: BubbleView) {
        assert(bubble.index != nil)
        let newSnap = UISnapBehavior(item: bubble, snapToPoint: self.view.center)
        newSnap.damping = 0.1
        UIView.animateWithDuration(0.3) {
            bubble.center = self.view.center
        }
        animator.addBehavior(newSnap)
        focusedSnap = newSnap
        view.focusedBubble = bubble
    }

    func disengageFocused(bubble: BubbleView) {
        // Remove the old bubble
        if let snap = focusedSnap {
            animator.removeBehavior(snap)
        }

        view.focusedBubble = nil
        focusedSnap = nil
    }

    // MARK: Device Motion

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

    internal func layoutChanged() {
        if let focused = view.focusedBubble {
            // Snap the bubble to the new center
            focusedSnap?.snapPoint = view.center
        }
    }

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