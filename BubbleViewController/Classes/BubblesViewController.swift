import UIKit

public class BubblesViewController: UIViewController, UICollisionBehaviorDelegate {
    public var bubblesView = BubblesView(frame: CGRectZero)

    // MARK: Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func loadView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = .whiteColor()
        view.addSubview(bubblesView)
        bubblesView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        bubblesView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        bubblesView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        bubblesView.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
    }

}
