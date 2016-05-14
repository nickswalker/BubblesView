import Foundation

class BubbleBehavior: UIDynamicBehavior {

    private let item: UIDynamicItem

    private let itemBehavior: UIDynamicItemBehavior

    init(item: UIDynamicItem) {
        self.item = item
        itemBehavior = UIDynamicItemBehavior(items: [item])
        itemBehavior.density = 0.01
        itemBehavior.resistance = 5
        itemBehavior.friction = 0.0
        itemBehavior.allowsRotation = false

        super.init()

        addChildBehavior(itemBehavior)

    }

    func addLinearVelocity(velocity: CGPoint) {
        itemBehavior.addLinearVelocity(velocity, forItem: item)
    }

}