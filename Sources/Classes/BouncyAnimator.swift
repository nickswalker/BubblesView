import Foundation
import CoreMotion

public class BouncyAnimator: BubblesViewAnimator {
    private var animator: UIDynamicAnimator!
    public weak var view: BubblesView!

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

    required public init(owner: BubblesView) {
        self.view = owner
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
        animator.removeBehavior(bubbleBehaviors[bubble]!)
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
        let attachment = relatedAttachments.removeValueForKey(bubble)
        animator.removeBehavior(attachment!)
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