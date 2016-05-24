import Foundation
import CoreMotion

public protocol BubblesViewDataSource {
    func focusedBubble() -> Int
    func relatedForBubble(bubble: Int) -> Set<Int>
    func configureBubble(index: Int) -> BubbleView
}

public protocol BubblesViewDelegate {
    func didSelectBubble(bubble: Int)
}

public class BubblesView: UIView {

    private var tapRecognizers = [BubbleView: UITapGestureRecognizer]()
    private var panRecognizers = [BubbleView: UIPanGestureRecognizer]()

    private var indexToBubble = [Int: BubbleView]()
    private var currentRelated = Set<Int>()

    public var dataSource: BubblesViewDataSource?
    public var delegate: BubblesViewDelegate?

    private var positionClock = PositionClock(divisions: 7, radius: 120)

    private var offset = CGPointZero

    public private(set) var animator: BubblesViewAnimator!

    var focusedBubble: BubbleView?

    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        animator = BubblesViewAnimator(owner: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        animator.layoutChanged()
    }

    /**
     Tear everything down and load afresh
     */
    public func reloadData() {
        guard let dataSource = dataSource else {
            return
        }

        // Remove focused
        if let oldFocused = focusedBubble {
            animator.disengageFocused(oldFocused)
            removeBubble(oldFocused)
        }

        // Remove all related
        let currentRelatedViews = currentRelated.map{indexToBubble[$0]}.flatMap{$0}
        currentRelatedViews.forEach{removeBubble($0)}

        // Add new focused
        let focusedIndex = dataSource.focusedBubble()
        let newFocused = dataSource.configureBubble(focusedIndex)
        newFocused.index = focusedIndex
        addBubble(newFocused, origin: center)
        animator.configureFocused(newFocused)

        // Add new related
        let related = dataSource.relatedForBubble(focusedIndex)
        currentRelated = related
        let relatedBubbles = related.forEach { index in
            let bubble = dataSource.configureBubble(index)
            bubble.index = index
            let position = positionClock.advance(withCenter: center)
            self.addBubble(bubble, origin: position)
            self.animator.addAttachment(bubble)
        }
    }

    /**
     Dynamically reconfigures the graph to have a new focus node. Animates out unrelated nodes, preserving
     shared relations and removing unrelated nodes.

     - parameter bubble: <#bubble description#>
     */
    public func focus(index focusIndex: Int) {
        // The bubbles will be in a bad state while the update occurs.
        // Let's make sure that users can't break things
        let old = userInteractionEnabled
        userInteractionEnabled = false
        defer {
            userInteractionEnabled = old
        }
        // If the correct bubble is already focused, we're done.
        if focusedBubble?.index == focusIndex {
            return
        }

        let newRelated = dataSource!.relatedForBubble(focusIndex)
        assert(!newRelated.contains(focusIndex))
        // Add ones that aren't in the current related
        let toAdd: Set<Int> = {
            var temp = newRelated.subtract(currentRelated)
            // The current focused bubble is already in the hiearchy, so we'll
            // handle connecting it seperately
            temp.remove(focusedBubble?.index ?? -2)
            return temp
        }()

        // Remove ones aren't also in the new related. Note that the focused view isn't
        // related to itself, so if the current related contains the new focus target,
        // let's *not* remove it
        let toRemove: Set<Int> = {
            var temp = currentRelated.subtract(newRelated)
            temp.remove(focusIndex)
            return temp
        }()
        let removeViews = toRemove.map{self.indexToBubble[$0]!}
        removeViews.forEach{self.animator.removeAttachment($0)}
        removeViews.forEach{self.removeBubble($0)}

        let toKeep = newRelated.intersect(currentRelated)
        // The keepers still need to be disengaged from the current focus
        let keepViews = toKeep.map{self.indexToBubble[$0]!}
        keepViews.forEach{self.animator.removeAttachment($0)}

        // Focus.
        // Is there a current focused?
        let oldFocused = focusedBubble
        if let oldFocused = oldFocused {
            self.animator.disengageFocused(oldFocused)
        }

        assert(focusedBubble == nil)
        // Two possibilities: focus target was in the current related, or wasn't
        if(currentRelated.contains(focusIndex)) {
            // It would be in removeViews, but we specifically excluded it. We need
            // to remove its relation
            let toBeFocused = indexToBubble[focusIndex]!
            animator.removeAttachment(toBeFocused)
            animator.configureFocused(toBeFocused)
        } else {
            // Get the fresh focused view
            let newFocused = self.dataSource!.configureBubble(focusIndex)
            newFocused.index = focusIndex
            // We have to add it to the hierarchy
            addBubble(newFocused, origin: center)
            animator.configureFocused(newFocused)
        }

        assert(focusedBubble?.index == focusIndex)

        if let oldFocused = oldFocused {
            // Two cases. Current focused is in the new related or it isn't
            if (newRelated.contains(oldFocused.index!)) {

                animator.addAttachment(oldFocused)
            } else {
                removeBubble(oldFocused)
            }
        }

        keepViews.forEach{self.animator.addAttachment($0)}

        let addViews = toAdd.map{ index -> BubbleView in
            let newBubble = self.dataSource!.configureBubble(index)
            newBubble.index = index
            return newBubble
        }
        addViews.forEach{let position = self.positionClock.advance(withCenter: self.center)
            self.addBubble($0, origin: position)}
        addViews.forEach{self.animator.addAttachment($0)}
        currentRelated = newRelated

        // Make sure we aren't leaking resources
        assert(tapRecognizers.count == 1 + currentRelated.count)
        assert(panRecognizers.count == 1 + currentRelated.count)
        /*assert(relatedAttachments.count == currentRelated.count)
        assert(gravityBehavior.items.count == 1 + currentRelated.count)
        assert(collisionBehavior.items.count == 1 + currentRelated.count)
         */
    }

    // MARK: Gesture Recognizers
    func didTapBubble(recognizer: UITapGestureRecognizer){
        let target = recognizer.view as! BubbleView
        // It's possible for a bubble to be tapped shortly after its index is niled out
        if let index = target.index {
            delegate?.didSelectBubble(index)
        }
    }

    func didPanBubble(recognizer: UIPanGestureRecognizer) {
        let target = recognizer.view as! BubbleView

        // Don't allow dragging the focused
        if target == focusedBubble {
            return
        }
        let location = recognizer.locationInView(self)
        switch recognizer.state {
        case .Began:
            // Nothing should come between the user's finger and the view
            self.bringSubviewToFront(target)
            // Capture the initial touch offset from the itemView's center.
            let center = target.center
            offset.x = location.x - center.x
            offset.y = location.y - center.y

            // Free the bubble from animator
            animator.removeAttachment(target)
            animator.removeBehaviors(target)
            target.transform = CGAffineTransformMakeScale(1.05, 1.05)
        case .Cancelled, .Ended:
            animator.addAttachment(target)
            animator.addBehaviors(target)
            target.transform = CGAffineTransformIdentity

            let velocity = recognizer.velocityInView(self)
            let amplifiedVelocity = CGVector(dx: velocity.x * 2.0, dy: velocity.y * 2.0)
            animator.addVelocity(target, velocity: amplifiedVelocity)
        case .Changed:

            let referenceBounds = bounds
            let referenceWidth = referenceBounds.width
            let referenceHeight = referenceBounds.height

            // Get item bounds.
            let itemBounds = target.bounds
            let itemHalfWidth = itemBounds.width / 2.0
            let itemHalfHeight = itemBounds.height / 2.0

            var newLocation = location
            // Apply the initial offset.
            newLocation.x -= offset.x
            newLocation.y -= offset.y

            // Bound the item position inside the reference view.
            newLocation.x = max(itemHalfWidth, newLocation.x)
            newLocation.x = min(referenceWidth - itemHalfWidth, newLocation.x)
            newLocation.y = max(itemHalfHeight, newLocation.y)
            newLocation.y = min(referenceHeight - itemHalfHeight, newLocation.y)

            // Apply the resulting item center.
            target.center = newLocation
        default:
            ()
        }
    }

    // MARK: Bubble insertion/removal
    private func addBubble(bubble: BubbleView, origin: CGPoint) {
        assert(bubble.index != -1)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBubble))
        bubble.addGestureRecognizer(tapRecognizer)
        tapRecognizers[bubble] = tapRecognizer

        let panRecognizer = UIPanGestureRecognizer()
        panRecognizer.addTarget(self, action: #selector(didPanBubble))
        bubble.addGestureRecognizer(panRecognizer)
        panRecognizers[bubble] = panRecognizer

        bubble.frame = CGRect(origin: origin, size: CGSize(width: 100, height: 100))
        bubble.transform = CGAffineTransformMakeScale(0.1, 0.1)
        addSubview(bubble)
        indexToBubble[bubble.index!] = bubble
        animator.addBehaviors(bubble)

        animator.animateToNormalSize(bubble)
    }

    private func removeBubble(bubble: BubbleView) {
        panRecognizers.removeValueForKey(bubble)
        tapRecognizers.removeValueForKey(bubble)
        animator.removeBehaviors(bubble)
        animator.animateRemoveSubview(bubble)
        indexToBubble.removeValueForKey(bubble.index!)
        bubble.index = nil
    }

}

private func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
}