//
//  ListItemValueRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The stored row holding one field value of an item, such as its weight or price.
@Table("listItemValues")
struct ListItemValueRecord: Equatable, Sendable {
    let itemID: String
    /// The ``ListField`` raw value.
    let field: String
    /// The value in its stored form; see ``ListFieldValue``.
    let value: String

    /// Creates one row per value of `item`.
    static func records(for item: ListItem) -> [ListItemValueRecord] {
        item.values.map { field, value in
            ListItemValueRecord(itemID: item.identifier, field: field.rawValue, value: value.storedValue)
        }
    }
}
