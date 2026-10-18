//
//  ListItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for a ``ListItem``.
///
/// An item is standalone: ``ListItemLinkRecord`` rows attach it to sections, so one item can be
/// shared. Its field values live in ``ListItemValueRecord``.
@Table("listItems")
struct ListItemRecord: Equatable, Sendable {
    let id: String
    var name: String

    /// Creates a row from a public ``ListItem``.
    init(_ item: ListItem) {
        id = item.identifier
        name = item.name
    }

    /// Rebuilds the public ``ListItem`` from this row and its value rows.
    ///
    /// Values that can't be read, or belong to an unknown field, are skipped.
    func makeListItem(values: [ListItemValueRecord]) -> ListItem {
        let pairs = values.compactMap { record -> (ListField, ListFieldValue)? in
            guard
                let field = ListField(rawValue: record.field),
                let value = ListFieldValue(field: field, storedValue: record.value)
            else { return nil }
            return (field, value)
        }
        return ListItem(
            identifier: id,
            name: name,
            values: Dictionary(pairs, uniquingKeysWith: { first, _ in first })
        )
    }
}
