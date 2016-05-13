import Foundation
import UIKit

public class BubbleView: UIView {
    public var label = UILabel()
    public var imageView = UIImageView()

    internal var index: Int?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        addSubview(imageView)
        imageView.leadingAnchor.constraintEqualToAnchor(leadingAnchor)
        imageView.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
        imageView.topAnchor.constraintEqualToAnchor(topAnchor)
        imageView.bottomAnchor.constraintEqualToAnchor(bottomAnchor)

        label.textColor = .whiteColor()
        label.textAlignment = .Center
    }

    override public func layoutSubviews() {
        label.frame = CGRect(x: 10, y: frame.height / 2.0 - label.frame.height / 2.0, width: frame.width - 20.0, height: 30)
        layer.cornerRadius = frame.width / 2.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

