import UIKit

public protocol BubbleViewDataSource {
    func focusedBubble() -> Int
    func relatedForBubble(bubble: Int) -> Set<Int>
    func configureBubble(index: Int) -> BubbleView
}

public protocol BubbleViewDelegate {
    func didSelectBubble(bubble: Int)
}

public class BubbleViewController: UIViewController {
    public var dataSource: BubbleViewDataSource?
    public var delegate: BubbleViewDelegate?
    var animator: UIDynamicAnimator!

    private var focusedBubble: BubbleView?
    private var focusedSnap: UISnapBehavior?

    private var indexToBubble = [Int: BubbleView]()
    private var currentRelated = Set<Int>()
    private var relatedAttachments = [BubbleView: UIAttachmentBehavior]()
    private var bubbleBehaviors = [BubbleView: BubbleBehavior]()
    private var collisionBehavior = UICollisionBehavior()

    private var offset = CGPointZero


    private var tapRecognizers = [BubbleView: UITapGestureRecognizer]()
    private var panRecognizers = [BubbleView: UIPanGestureRecognizer]()
    public override func viewDidLoad() {
        animator = UIDynamicAnimator(referenceView: view)
        collisionBehavior.collisionMode = .Everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collisionBehavior)
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

    public override func viewWillLayoutSubviews() {

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
            newFocused.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
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
        let newSnap = UISnapBehavior(item: bubble, snapToPoint: CGPoint(x: view.frame.width / 2.0, y: view.frame.height / 2.0))
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
        let attachment = UIAttachmentBehavior.limitAttachmentWithItem(bubble, offsetFromCenter: UIOffsetZero, attachedToItem: focusedBubble!, offsetFromCenter: UIOffsetZero)
        attachment.length = 120
        relatedAttachments[bubble] = attachment
        animator.addBehavior(attachment)
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
        let location = recognizer.locationInView(view)
        switch recognizer.state {
        case .Began:

            // Capture the initial touch offset from the itemView's center.
            let center = target.center
            offset.x = location.x - center.x
            offset.y = location.y - center.y

            // Free bubble from animator
            removeAttachment(target)
            removeBehaviors(target)
        case .Cancelled, .Ended:
            addAttachment(target)
            addBehaviors(target)
            let behavior = bubbleBehaviors[target]
            let velocity = recognizer.velocityInView(view)
            let amplifiedVelocity = CGPoint(x: velocity.x * 2.0, y: velocity.y * 2.0)
            behavior!.addLinearVelocity(amplifiedVelocity)
        case .Changed:

            let referenceBounds = view.bounds
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
        bubble.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.addSubview(bubble)
        indexToBubble[bubble.index!] = bubble
        addBehaviors(bubble)
    }

    private func removeBubble(bubble: BubbleView) {
        tapRecognizers.removeValueForKey(bubble)
        removeBehaviors(bubble)
        bubble.removeFromSuperview()
        indexToBubble.removeValueForKey(bubble.index!)
        bubble.index = nil
    }
}
