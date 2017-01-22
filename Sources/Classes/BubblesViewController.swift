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

import UIKit

/// View controller with a BubblesView pinned to all sides of its view.
open class BubblesViewController: UIViewController {
    /// The BubblesView being managed
    open var bubblesView = BubblesView(frame: CGRect.zero)

    // MARK: Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .white
        view.addSubview(bubblesView)
        bubblesView.translatesAutoresizingMaskIntoConstraints = false
        let top = bubblesView.topAnchor.constraint(equalTo: view.topAnchor)
        let right = bubblesView.rightAnchor.constraint(equalTo: view.rightAnchor)
        let bottom = bubblesView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let left = bubblesView.leftAnchor.constraint(equalTo: view.leftAnchor)
        view.addConstraints([top, right, bottom, left])
        view.setNeedsLayout()
    }

}
