import Foundation

public protocol BubblesViewDataSource {
    func focusedBubble() -> Int
    func relatedForBubble(bubble: Int) -> Set<Int>
    func configureBubble(index: Int) -> BubbleView
}

public protocol BubblesViewDelegate {
    func didSelectBubble(bubble: Int)
}

public class BubblesView: UIView {
    var animator: UIDynamicAnimator!

    private var focusedBubble: BubbleView?
    private var focusedSnap: UISnapBehavior?

    private var bubbleBehaviors = [BubbleView: BubbleBehavior]()
    private var collisionBehavior = UICollisionBehavior()

    private var tapRecognizers = [BubbleView: UITapGestureRecognizer]()
    private var panRecognizers = [BubbleView: UIPanGestureRecognizer]()

    private var indexToBubble = [Int: BubbleView]()
    private var currentRelated = Set<Int>()
    private var relatedAttachments = [BubbleView: UIAttachmentBehavior]()

    public var dataSource: BubblesViewDataSource?
    public var delegate: BubblesViewDelegate?

    private var offset = CGPointZero

    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        animator = UIDynamicAnimator(referenceView: self)
        collisionBehavior.collisionMode = .Everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collisionBehavior)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        if let focused = focusedBubble {
            // Snap the bubble to the new center
            disengageFocused(focused)
            configureFocused(focused)
        }
    }

    /**
     Tear everything down and load afresh
     */
    public func reloadData() {
        guard let dataSource = dataSource else {
            return
        }

        if let oldFocused = focusedBubble {
            disengageFocused(oldFocused)
            removeBubble(oldFocused)
        }

        let currentRelatedViews = currentRelated.map{indexToBubble[$0]}
        currentRelatedViews.forEach{self.disengageRelated($0!)}
        currentRelatedViews.forEach{removeBubble($0!)}

        let focusedIndex = dataSource.focusedBubble()
        let newFocused = dataSource.configureBubble(focusedIndex)
        newFocused.index = focusedIndex
        addBubble(newFocused)
        configureFocused(newFocused)

        let related = dataSource.relatedForBubble(focusedIndex)
        currentRelated = related
        let relatedBubbles = related.forEach { index in
            let bubble = dataSource.configureBubble(index)
            bubble.index = index
            addBubble(bubble)
            self.configureRelated(bubble)
            self.addAttachment(bubble)
        }
    }


    /**
     Dynamically reconfigures the graph to have a new focus node. Animates out unrelated nodes, preserving
     shared relations and removing unrelated nodes.

     - parameter bubble: <#bubble description#>
     */
    public func focus(bubbleIndex: Int) {
        // If the correct bubble is already focused, we're done.
        if focusedBubble?.index == bubbleIndex {
            return
        }
        let newRelated = dataSource!.relatedForBubble(bubbleIndex)
        assert(!newRelated.contains(bubbleIndex))
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
            temp.remove(bubbleIndex)
            return temp
        }()
        let removeViews = toRemove.map{self.indexToBubble[$0]!}
        removeViews.forEach{self.disengageRelated($0)}
        removeViews.forEach{self.removeAttachment($0)}
        removeViews.forEach{self.removeBubble($0)}

        let toKeep = newRelated.intersect(currentRelated)
        // The keepers still need to be disengaged from the current focus
        let keepViews = toKeep.map{self.indexToBubble[$0]!}
        keepViews.forEach{self.removeAttachment($0)}

        // Focus.
        // Is there a current focused?
        let oldFocused = focusedBubble
        if let oldFocused = oldFocused {
            disengageFocused(oldFocused)
        }

        assert(focusedBubble == nil)
        // Two possibilities: focus target was in the current related, or wasn't
        if(currentRelated.contains(bubbleIndex)) {
            // It would be in removeViews, but we specifically excluded it. We need
            // to remove its relation
            let toBeFocused = indexToBubble[bubbleIndex]!
            disengageRelated(toBeFocused)
            removeAttachment(toBeFocused)
            configureFocused(toBeFocused)
        } else {
            // Get the fresh focused view
            let newFocused = self.dataSource!.configureBubble(bubbleIndex)
            newFocused.index = bubbleIndex
            // We have to add it to the hiearchy
            newFocused.frame = CGRect(origin: center, size: CGSize(width: 100.0, height: 100.0))
            addBubble(newFocused)
            configureFocused(newFocused)
        }

        assert(focusedBubble?.index == bubbleIndex)

        if let oldFocused = oldFocused {
            // Two cases. Current focused is in the new related or it isn't
            if (newRelated.contains(oldFocused.index!)) {
                configureRelated(oldFocused)
                addAttachment(oldFocused)
            } else {
                removeBubble(oldFocused)
            }
        }

        keepViews.forEach{self.addAttachment($0)}

        let addViews = toAdd.map{ index -> BubbleView in
            let newBubble = self.dataSource!.configureBubble(index)
            newBubble.index = index
            return newBubble
        }
        addViews.forEach{self.addBubble($0)}
        addViews.forEach{self.configureRelated($0)}
        addViews.forEach{self.addAttachment($0)}
        currentRelated = newRelated

        assert(relatedAttachments.count == currentRelated.count)
    }

    // MARK: Focus
    private func configureFocused(bubble: BubbleView) {
        assert(bubble.index != nil)
        //animateGrow(bubble)
        let newSnap = UISnapBehavior(item: bubble, snapToPoint: center)
        newSnap.damping = 0.5
        animator.addBehavior(newSnap)
        focusedSnap = newSnap
        focusedBubble = bubble
    }

    private func disengageFocused(bubble: BubbleView) {
        // Remove the old bubble
        tapRecognizers.removeValueForKey(bubble)
        if let snap = focusedSnap {
            animator.removeBehavior(snap)
        }

        //animateToNormalSize(bubble)

        focusedBubble = nil
        focusedSnap = nil
    }

    // MARK: Related

    private func configureRelated(bubble: BubbleView){
        assert(bubble.index != nil)
        let panRecognizer = UIPanGestureRecognizer()
        panRecognizer.addTarget(self, action: #selector(didPanBubble))
        bubble.addGestureRecognizer(panRecognizer)
        panRecognizers[bubble] = panRecognizer
    }

    private func disengageRelated(bubble: BubbleView){
        bubble.removeGestureRecognizer(panRecognizers[bubble]!)
        panRecognizers.removeValueForKey(bubble)
    }

    // MARK: Behaviors
    private func addBehaviors(bubble: BubbleView){
        let bubbleBehavior = BubbleBehavior(item: bubble)
        bubbleBehaviors[bubble] = bubbleBehavior
        animator.addBehavior(bubbleBehavior)
        collisionBehavior.addItem(bubble)
    }

    private func removeBehaviors(bubble: BubbleView) {
        animator.removeBehavior(bubbleBehaviors[bubble]!)
        bubbleBehaviors.removeValueForKey(bubble)
        collisionBehavior.removeItem(bubble)
    }

    private func addAttachment(bubble: BubbleView) {
        assert(focusedBubble != nil)
        let attachment = UIAttachmentBehavior(item: bubble, attachedToItem: focusedBubble!)
        attachment.length = 120
        relatedAttachments[bubble] = attachment
        animator.addBehavior(attachment)
        collisionBehavior.addItem(bubble)
    }

    private func removeAttachment(bubble: BubbleView) {
        let attachment = relatedAttachments.removeValueForKey(bubble)
        animator.removeBehavior(attachment!)
    }

    // MARK: Gesture Recognizers
    func didTapBubble(recognizer: UITapGestureRecognizer){
        let target = recognizer.view as! BubbleView
        delegate?.didSelectBubble(target.index!)
    }

    func didPanBubble(recognizer: UIPanGestureRecognizer) {
        let target = recognizer.view as! BubbleView
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
            removeAttachment(target)
            removeBehaviors(target)
            target.transform = CGAffineTransformMakeScale(1.05, 1.05)
        case .Cancelled, .Ended:
            addAttachment(target)
            addBehaviors(target)
            target.transform = CGAffineTransformIdentity
            let behavior = bubbleBehaviors[target]
            let velocity = recognizer.velocityInView(self)
            let amplifiedVelocity = CGPoint(x: velocity.x * 2.0, y: velocity.y * 2.0)
            behavior!.addLinearVelocity(amplifiedVelocity)
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
    private func addBubble(bubble: BubbleView) {
        assert(bubble.index != -1)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBubble))
        bubble.addGestureRecognizer(tapRecognizer)
        tapRecognizers[bubble] = tapRecognizer
        bubble.frame = CGRect(origin: center, size: CGSize(width: 100, height: 100))
        addSubview(bubble)
        indexToBubble[bubble.index!] = bubble
        addBehaviors(bubble)
    }

    private func removeBubble(bubble: BubbleView) {
        tapRecognizers.removeValueForKey(bubble)
        removeBehaviors(bubble)
        animateRemoveSubview(bubble)
        indexToBubble.removeValueForKey(bubble.index!)
        bubble.index = nil
    }

    // MARK: Animation
    private func animateRemoveSubview(view: UIView) {
        // The view shouldn't cover anything as it leaves
        sendSubviewToBack(view)
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 2.0, options: .CurveEaseIn, animations: {
            view.transform = CGAffineTransformMakeScale(0.1, 0.1)
        }) { (_) in
            view.removeFromSuperview()
        }
    }

    private func animateGrow(view: UIView) {
        animateToScale(view, scale: 1.2)
    }

    private func animateToNormalSize(view: UIView) {
        animateToScale(view, scale: 1.0)
    }

    private func animateToScale(view: UIView, scale: CGFloat) {
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 2.0, options: .CurveEaseIn, animations: {
            view.transform = CGAffineTransformMakeScale(scale, scale)
        }) { (_) in
            view.transform = CGAffineTransformMakeScale(scale, scale)
        }
    }
}