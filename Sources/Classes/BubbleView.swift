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
import UIKit

/// A circle with a centered label and/or a background image.
public class BubbleView: UIView {
    public var label = UILabel()
    public var imageView = UIImageView()

    /// The index that this bubble represents in its parent BubblesView
    internal var index: Int?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        addSubview(imageView)

        translatesAutoresizingMaskIntoConstraints = false

        imageView.backgroundColor = .clearColor()
        let leading = imageView.leadingAnchor.constraintEqualToAnchor(leadingAnchor)
        let trailing = imageView.trailingAnchor.constraintEqualToAnchor(trailingAnchor)
        let top = imageView.topAnchor.constraintEqualToAnchor(topAnchor)
        let bottom = imageView.bottomAnchor.constraintEqualToAnchor(bottomAnchor)
        //addConstraints([leading, trailing, top, bottom])

        label.textColor = .whiteColor()
        label.font = UIFont.boldSystemFontOfSize(21.0)
        label.textAlignment = .Center

        let centerX = label.centerXAnchor.constraintEqualToAnchor(centerXAnchor)
        let centerY = label.centerYAnchor.constraintEqualToAnchor(centerYAnchor)

        //addConstraints([centerX, centerY])
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(origin: CGPointZero, size: label.intrinsicContentSize())
        label.frame = CGRect(x: 10, y: frame.height / 2.0 - label.frame.height / 2.0, width: frame.width - 20.0, height: 30)
        layer.cornerRadius = frame.width / 2.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .Ellipse
    }
}

