import Foundation

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
        storage = [UInt](count: size,repeatedValue: 0)
    }

    private func parent(index: Int) -> Int {
        return ((index - 1) / numChildren)
    }

    func children(index: Int) -> [Int] {
        var result = [Int]()
        (1...numChildren).forEach{result.append(self.numChildren * index + $0)}
        return result
    }

    func isLeaf(index: Int) -> Bool {
        return children(index).first >= size
    }

    func generateInOrderTraversal() -> [Int] {
        var result = [Int]()
        inOrder(root, list: &result)
        assert(result.count == size)
        return result
    }

    private func inOrder(index: Int, inout list: [Int]) {
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