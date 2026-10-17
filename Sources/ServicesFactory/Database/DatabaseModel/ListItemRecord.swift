//
//  ListItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation
import SQLiteData

/// The stored row for a ``ListItem``.
@Table("listItems")
struct ListItemRecord: Equatable, Sendable {
    let id: String
    let listID: String
    var name: String
    /// The item weight in grams, or `nil` when the list has no weight field.
    var weightInGrams: Double?
    /// The item's index in its list, preserving display order.
    var position: Int

    /// Creates a row from a public ``ListItem`` at `position` within the list `listID`.
    init(_ item: ListItem, listID: String, position: Int) {
        id = item.identifier
        self.listID = listID
        name = item.name
        weightInGrams = item.weight?.converted(to: .grams).value
        self.position = position
    }

    /// Creates one row per item of `list`, in order.
    static func records(for list: List) -> [ListItemRecord] {
        list.items.enumerated().map { index, item in
            ListItemRecord(item, listID: list.identifier, position: index)
        }
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
