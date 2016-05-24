import UIKit

public class BubblesViewController: UIViewController {
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
        bubblesView.translatesAutoresizingMaskIntoConstraints = false
        let top = bubblesView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        let right = bubblesView.rightAnchor.constraintEqualToAnchor(view.rightAnchor)
        let bottom = bubblesView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        let left = bubblesView.leftAnchor.constraintEqualToAnchor(view.leftAnchor)
        view.addConstraints([top, right, bottom, left])
        view.setNeedsLayout()
    }

}
