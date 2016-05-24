import Foundation

public protocol BubblesViewAnimator {
    weak var view: BubblesView! { get }

    init(owner: BubblesView)

    func addBehaviors(bubble: BubbleView)
    func removeBehaviors(bubble: BubbleView)

    func addRelatedBehaviors(bubble: BubbleView)
    func removeRelatedBehaviors(bubble: BubbleView)

    func addFocusedBehaviors(bubble: BubbleView)
    func removeFocusedBehaviors(bubble: BubbleView)

    func addVelocity(bubble: BubbleView, velocity: CGVector)

    func layoutChanged()
}

extension BubblesViewAnimator {
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