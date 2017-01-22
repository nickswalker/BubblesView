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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class CompleteKaryTree {
    let height: Int
    let size: Int
    let numChildren: Int
    let root: Int

    var storage: [UInt]

    // MARK: Initialization
    init(children: Int, height: Int) {
        self.height = height
        self.numChildren = children
        let numerator = Float(pow(children, height + 1) - 1)
        let denominator = Float(children - 1)
        size = Int(numerator / denominator)
        root = 0
        storage = [UInt](repeating: 0,count: size)
    }

    fileprivate func parent(_ index: Int) -> Int {
        return ((index - 1) / numChildren)
    }

    func children(_ index: Int) -> [Int] {
        var result = [Int]()
        (1...numChildren).forEach{result.append(self.numChildren * index + $0)}
        return result
    }

    func isLeaf(_ index: Int) -> Bool {
        return children(index).first >= size
    }

    func generateInOrderTraversal() -> [Int] {
        var result = [Int]()
        inOrder(root, list: &result)
        assert(result.count == size)
        return result
    }

    fileprivate func inOrder(_ index: Int, list: inout [Int]) {
        guard !isLeaf(index) else {
            list.append(index)
            return
        }
        let curChildren = self.children(index)
        for i in 0..<(numChildren/2) {
            inOrder(curChildren[i], list: &list)
        }
        list.append(index)
        for i in (numChildren/2)..<numChildren {
            inOrder(curChildren[i], list: &list)
        }
    }
}
