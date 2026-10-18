//
//  ChecklistItem.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation

/// An item in a ``ChecklistComponent``.
///
/// An item belongs to exactly one component. Reusing an item in another checklist copies it, so
/// changing or completing one copy never affects another.
public struct ChecklistItem: Sendable {
    /// The unique identifier of the item.
    public let identifier: String
    /// The display title of the item.
    public let title: String
    /// The weight of the item, if it has one. Shown when the checklist's type is ``ChecklistType/weight``.
    public let weight: Measurement<UnitMass>?
    /// The price of the item, if it has one, in the user's own currency. Shown when the checklist's type is ``ChecklistType/price``.
    public let price: Decimal?
    /// The encoded image of the item, if it has one.
    public let imageData: Data?
    /// Whether the item has been completed.
    public let isCompleted: Bool

    /// Creates an item with the given identifier, title, optional details and completion state.
    public init(
        identifier: String,
        title: String,
        weight: Measurement<UnitMass>? = nil,
        price: Decimal? = nil,
        imageData: Data? = nil,
        isCompleted: Bool = false
    ) {
        self.identifier = identifier
        self.title = title
        self.weight = weight
        self.price = price
        self.imageData = imageData
        self.isCompleted = isCompleted
    }
}
