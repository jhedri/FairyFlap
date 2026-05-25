import ObjectiveC
import SpriteKit

extension SKNode {

    private nonisolated(unsafe) static var identifierKey: UInt8 = 0

    /// Accessibility identifier for XCUITest queries on SpriteKit nodes.
    var accessibilityIdentifier: String? {
        get { objc_getAssociatedObject(self, &Self.identifierKey) as? String }
        set { objc_setAssociatedObject(self, &Self.identifierKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}
