//
//  ListItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation
import SQLiteData

/// The stored row for a ``ListItem``.
///
/// An item is standalone: ``ListItemLinkRecord`` rows attach it to lists, so one item can be shared.
@Table("listItems")
struct ListItemRecord: Equatable, Sendable {
    let id: String
    var name: String
    /// The item weight in grams, or `nil` when the item has no weight.
    var weightInGrams: Double?

    /// Creates a row from a public ``ListItem``.
    init(_ item: ListItem) {
        id = item.identifier
        name = item.name
        weightInGrams = item.weight?.converted(to: .grams).value
    }

    /// Rebuilds the public ``ListItem``.
    func makeListItem() -> ListItem {
        ListItem(
            identifier: id,
            name: name,
            weight: weightInGrams.map { Measurement(value: $0, unit: .grams) }
        )
    }
}
