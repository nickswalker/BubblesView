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

/**
 *  Provides information and configures views to represent the information.
 */
public protocol BubblesViewDataSource {
    /**
     Asks the data source for the index of the currently focused bubble

     - returns: the index of the currently focused bubble
     */
    func focusedBubble() -> Int

    /**
     Asks the data source for the set of related indices for an index.

     - parameter index: the index of which the related are desired

     - returns: the set of related indices for the parameter index
     */
    func relatedForBubble(index: Int) -> Set<Int>

    /**
     Asks the data source to prepare a BubbleView for the index

     - parameter index: the index to prepare the view to represent

     - returns: the view prepared to be presented
     */
    func configureBubble(index: Int) -> BubbleView
}

/**
 *  Gets notified of important events or user interactions with a BubblesView
 */
public protocol BubblesViewDelegate {
    /**
     Tells the delegate that a bubble was tapped.

     - parameter index: <#index description#>
     */
    func didSelectBubble(index: Int)
}

/// A view that displays an element and its associated elements. The associated
/// elements have no particular order.
public class BubblesView: UIView {

    public var dataSource: BubblesViewDataSource?
    public var delegate: BubblesViewDelegate?

    /// The object responsible for defining the animation of the bubbles.
    /// `reloadData` should be called after configuring a new animator
    public var animator: BubblesViewAnimator?

    /// If true, the user can pan bubbles.
    public var allowsDraggingBubbles = true

    private var tapRecognizers = [BubbleView: UITapGestureRecognizer]()
    private var panRecognizers = [BubbleView: UIPanGestureRecognizer]()

    /// Maps from indices to bubbles currently in the view hierarchy
    private var indexToBubble = [Int: BubbleView]()

    /// The results from `relatedForBubble` that are currently being displayed
    private var currentRelated = Set<Int>()

    /// The clock used to generate the position of bubbles added to the view.
    private var positionClock = PositionClock(divisions: 7, radius: 120)

    /// The exact points within the views that a user is currently dragging.
    /// Used to properly position the bubble relative to the user's finger
    /// during animation.
    private var dragOffsets = [BubbleView: CGPoint]()

    private(set) var focusedBubble: BubbleView?

    private var currentlyDragging: Bool {
        return dragOffsets.count != 0
    }

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        animator?.layoutChanged()
    }

    /**
     Removes all subviews, completely disengages the animation system and queries the dataSource to start
     over.
     */
    public func reloadData() {
        guard let dataSource = dataSource else {
            return
        }

        // Remove focused
        if let oldFocused = focusedBubble {
            animator?.removeFocusedBehaviors(oldFocused)
            removeBubble(oldFocused)
            focusedBubble = nil
        }

        // Remove all related
        let currentRelatedViews = currentRelated.map{indexToBubble[$0]}.flatMap{$0}
        currentRelatedViews.forEach{removeBubble($0)}

        // Add new focused
        let focusedIndex = dataSource.focusedBubble()
        let newFocused = dataSource.configureBubble(focusedIndex)
        newFocused.index = focusedIndex
        addBubble(newFocused, origin: center)
        focusedBubble = newFocused
        animator?.addFocusedBehaviors(newFocused)

        // Add new related
        let related = dataSource.relatedForBubble(focusedIndex)
        currentRelated = related
        related.forEach { index in
            let bubble = dataSource.configureBubble(index)
            bubble.index = index
            let position = positionClock.advance(withCenter: center)
            self.addBubble(bubble, origin: position)
            self.animator?.addRelatedBehaviors(bubble)
        }
    }

    /**
     Dynamically reconfigures the graph to have a new focus node. This node need not be in the set indices related
     to the currently focused node. If an animator is configured, it will be used to provide a smooth 
     transition, animating out unrelated nodes, preserving shared relations and removing unrelated nodes.

     - parameter index: the index of the bubble to focus.
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
        removeViews.forEach{self.animator?.removeRelatedBehaviors($0)}
        removeViews.forEach{self.removeBubble($0)}

        let toKeep = newRelated.intersect(currentRelated)
        // The keepers still need to be disengaged from the current focus
        let keepViews = toKeep.map{self.indexToBubble[$0]!}
        keepViews.forEach{self.animator?.removeRelatedBehaviors($0)}

        // Focus.
        // Is there a current focused?
        let oldFocused = focusedBubble
        if let oldFocused = oldFocused {
            self.animator?.removeFocusedBehaviors(oldFocused)
            focusedBubble = nil
        }

        assert(focusedBubble == nil)
        // Two possibilities: focus target was in the current related, or wasn't
        if(currentRelated.contains(focusIndex)) {
            // It would be in removeViews, but we specifically excluded it. We need
            // to remove its relation
            let toBeFocused = indexToBubble[focusIndex]!
            animator?.removeRelatedBehaviors(toBeFocused)
            focusedBubble = toBeFocused
            animator?.addFocusedBehaviors(toBeFocused)
        } else {
            // Get the fresh focused view
            let newFocused = self.dataSource!.configureBubble(focusIndex)
            newFocused.index = focusIndex
            // We have to add it to the hierarchy
            addBubble(newFocused, origin: center)
            focusedBubble = newFocused
            animator?.addFocusedBehaviors(newFocused)
        }

        assert(focusedBubble?.index == focusIndex)

        if let oldFocused = oldFocused {
            // Two cases. Current focused is in the new related or it isn't
            if (newRelated.contains(oldFocused.index!)) {

                animator?.addRelatedBehaviors(oldFocused)
            } else {
                removeBubble(oldFocused)
            }
        }

        keepViews.forEach{self.animator?.addRelatedBehaviors($0)}

        let addViews = toAdd.map{ index -> BubbleView in
            let newBubble = self.dataSource!.configureBubble(index)
            newBubble.index = index
            return newBubble
        }
        addViews.forEach{let position = self.positionClock.advance(withCenter: self.center)
            self.addBubble($0, origin: position)}
        addViews.forEach{self.animator?.addRelatedBehaviors($0)}
        currentRelated = newRelated

        // Make sure we aren't leaking resources
        assert(tapRecognizers.count == 1 + currentRelated.count)
        assert(panRecognizers.count == 1 + currentRelated.count)
    }

    // MARK: Gesture Recognizers
    func didTapBubble(recognizer: UITapGestureRecognizer){
        // Don't allow tapping mid pan. Bubbles are disengaged so 
        // the focus change could go poorly
        if currentlyDragging {
            return
        }
        let target = recognizer.view as! BubbleView
        // It's possible for a bubble to be tapped shortly after its index is niled out
        if let index = target.index {
            delegate?.didSelectBubble(index)
        }
    }

    func didPanBubble(recognizer: UIPanGestureRecognizer) {
        // Make sure we have a valid target, don't allow dragging the focused
        // and respect the bubble dragging option
        guard let target = recognizer.view as? BubbleView
            where target != focusedBubble && allowsDraggingBubbles
            else {
                return
        }

        let location = recognizer.locationInView(self)
        switch recognizer.state {
        case .Began:
            // Nothing should come between the user's finger and the view
            self.bringSubviewToFront(target)
            // Capture the initial touch offset from the itemView's center.
            var offset = CGPoint()
            let center = target.center
            offset.x = location.x - center.x
            offset.y = location.y - center.y
            dragOffsets[target] = offset

            // Free the bubble from animator
            animator?.removeRelatedBehaviors(target)
            animator?.removeBehaviors(target)
            target.transform = CGAffineTransformMakeScale(1.05, 1.05)
        case .Cancelled, .Ended:
            animator?.addRelatedBehaviors(target)
            animator?.addBehaviors(target)
            target.transform = CGAffineTransformIdentity

            let velocity = recognizer.velocityInView(self)
            let amplifiedVelocity = CGVector(dx: velocity.x * 2.0, dy: velocity.y * 2.0)
            animator?.addVelocity(target, velocity: amplifiedVelocity)
            dragOffsets.removeValueForKey(target)
        case .Changed:

            let referenceBounds = bounds
            let referenceWidth = referenceBounds.width
            let referenceHeight = referenceBounds.height

            // Get item bounds.
            let itemBounds = target.bounds
            let itemHalfWidth = itemBounds.width / 2.0
            let itemHalfHeight = itemBounds.height / 2.0

            var newLocation = location
            let offset = dragOffsets[target]!
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
        assert(bubble.index != nil)
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
        animator?.addBehaviors(bubble)

        animator?.animateToNormalSize(bubble)
    }

    private func removeBubble(bubble: BubbleView) {
        panRecognizers.removeValueForKey(bubble)
        tapRecognizers.removeValueForKey(bubble)
        animator?.removeBehaviors(bubble)
        animator?.animateRemoveSubview(bubble)
        indexToBubble.removeValueForKey(bubble.index!)
        bubble.index = nil
    }

}

private func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX))
}