//
//  ListItem.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation

/// An item belonging to a ``ListSection``.
///
/// Completion is tracked per ``EventRun``, not on the item, so an item can be shared by many lists.
public struct ListItem: Sendable {
    /// The unique identifier of the item.
    public let identifier: String
    /// The display name of the item.
    public let name: String
    /// The item's values by field. Only fields the owning list declares are meaningful to show.
    public let values: [ListField: ListFieldValue]

    /// The weight of the item, if it has one.
    public var weight: Measurement<UnitMass>? {
        guard case .weight(let weight) = values[.weight] else { return nil }
        return weight
    }

    /// The price of the item, if it has one.
    public var price: Decimal? {
        guard case .price(let price) = values[.price] else { return nil }
        return price
    }

    /// Creates an item with the given identifier, name and field values.
    public init(identifier: String, name: String, values: [ListField: ListFieldValue] = [:]) {
        self.identifier = identifier
        self.name = name
        self.values = values
    }

    /// Creates an item with an optional weight.
    public init(identifier: String, name: String, weight: Measurement<UnitMass>?) {
        self.init(
            identifier: identifier,
            name: name,
            values: weight.map { [.weight: .weight($0)] } ?? [:]
        )
    }
}
