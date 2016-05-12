import UIKit

public protocol BubbleViewDataSource {
    func focusedBubble() -> Int
    func relatedForBubble(bubble: Int) -> [Int]
    func configureBubble(index: Int) -> BubbleView
}

public protocol BubbleViewDelegate {
    func didSelectBubble(bubble: Int)
}

public class BubbleViewController: UIViewController {
    public var dataSource: BubbleViewDataSource?
    public var delegate: BubbleViewDelegate?
    var animator: UIDynamicAnimator!

    private var focusedBubble = BubbleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    private var bubbles = [BubbleView: Int]()
    private var relatedAttachments = [BubbleView: UIAttachmentBehavior]()
    private var noRotationBehavior = UIDynamicItemBehavior()
    private var collisionBehavior = UICollisionBehavior()
    private var focusedSnap: UISnapBehavior?

    private var tapRecognizers = [BubbleView: UITapGestureRecognizer]()
    private var panRecognizers = [BubbleView: UIPanGestureRecognizer]()
    public override func viewDidLoad() {
        animator = UIDynamicAnimator(referenceView: view)
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        noRotationBehavior.allowsRotation = false
        animator.addBehavior(noRotationBehavior)
        animator.addBehavior(collisionBehavior)
        view.addSubview(focusedBubble)
        setFocused(focusedBubble)
    }

    public func reloadData() {
        guard let dataSource = dataSource else {
            return
        }
        let focused = dataSource.focusedBubble()
        let focusedBubble = dataSource.configureBubble(focused)
        setFocused(focusedBubble)
        let related = dataSource.relatedForBubble(focused)
        let relatedBubbles = related.forEach { index in
            let bubble = self.dataSource?.configureBubble(index)
            self.addRelatedBubble(bubble!)
            self.bubbles[bubble!] = index
        }
    }

    public override func viewWillLayoutSubviews() {

    }

    private func setFocused(bubble:BubbleView){
        // Remove the old bubble
        tapRecognizers.removeValueForKey(bubble)
        removeBehaviors(focusedBubble)
        if let snap = focusedSnap {
            animator.removeBehavior(snap)
        }

        focusedBubble.removeFromSuperview()

        // Add the new one
        bubble.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.addSubview(bubble)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBubble))
        bubble.addGestureRecognizer(tapRecognizer)
        addBehaviors(bubble)
        let newSnap = UISnapBehavior(item: bubble, snapToPoint: CGPoint(x: view.frame.width / 2.0, y: view.frame.height / 2.0))
        animator.addBehavior(newSnap)
        focusedSnap = newSnap
        focusedBubble = bubble
    }

    private func addRelatedBubble(bubble: BubbleView){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBubble))
        bubble.addGestureRecognizer(tapRecognizer)
        let panRecognizer = UIPanGestureRecognizer()
        panRecognizer.addTarget(self, action: #selector(didPanBubble))
        bubble.addGestureRecognizer(panRecognizer)
        panRecognizers[bubble] = panRecognizer
        bubble.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.addSubview(bubble)
        addBehaviors(bubble)
        addAttachment(bubble)
    }

    private func removeRelatedBubble(bubble: BubbleView){
        removeBehaviors(bubble)
        panRecognizers.removeValueForKey(bubble)
        bubble.removeFromSuperview()
        bubbles.removeValueForKey(bubble)
    }

    // MARK: Behaviors
    private func addBehaviors(bubble: BubbleView){
        noRotationBehavior.addItem(bubble)
        collisionBehavior.addItem(bubble)
    }

    private func removeBehaviors(bubble: BubbleView) {
        noRotationBehavior.removeItem(bubble)
        collisionBehavior.removeItem(bubble)
    }

    private func addAttachment(bubble: BubbleView) {
        let attachment = UIAttachmentBehavior.limitAttachmentWithItem(bubble, offsetFromCenter: UIOffsetZero, attachedToItem: focusedBubble, offsetFromCenter: UIOffsetZero)
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
        delegate?.didSelectBubble(bubbles[target]!)
    }

    func didPanBubble(recognizer: UIPanGestureRecognizer) {
        let target = recognizer.view as! BubbleView
        switch recognizer.state {
        case .Began:
            print("began")
            // Free bubble from animator
            removeAttachment(target)
            removeBehaviors(target)
        case .Ended:
            print("ended")
            addAttachment(target)
            addBehaviors(target)
        case .Changed:
            print("changed")
            target.center = recognizer.locationInView(view)
        default:
            ()
        }
    }
}
