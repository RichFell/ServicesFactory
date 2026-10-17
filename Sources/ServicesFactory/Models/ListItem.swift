import Foundation

/// An item belonging to a ``List``.
///
/// Completion is tracked per ``Event``, not on the item, so a list can be shared by many events.
public struct ListItem: Sendable {
    /// The unique identifier of the item.
    public let identifier: String
    /// The display name of the item.
    public let name: String
    /// The weight of the item. Only set when the owning list contains ``ListField/weight``.
    public let weight: Measurement<UnitMass>?

    /// Creates an item with the given identifier, name, and optional weight.
    public init(identifier: String, name: String, weight: Measurement<UnitMass>? = nil) {
        self.identifier = identifier
        self.name = name
        self.weight = weight
    }
}
