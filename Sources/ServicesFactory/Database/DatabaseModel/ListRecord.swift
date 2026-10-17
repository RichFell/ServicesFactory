//
//  ListRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for a ``List``. Its fields and items live in ``ListFieldRecord`` and ``ListItemRecord``.
@Table("lists")
struct ListRecord: Equatable, Sendable {
    let id: String
    var title: String

    /// Creates a row from a public ``List``.
    init(_ list: List) {
        id = list.identifier
        title = list.title
    }

    /// Rebuilds the public ``List`` from this row and its related rows.
    func makeList(fields: [ListFieldRecord], items: [ListItemRecord]) -> List {
        List(
            identifier: id,
            title: title,
            fields: Set(fields.compactMap { ListField(rawValue: $0.field) }),
            items: items.sorted { $0.position < $1.position }.map { $0.makeListItem() }
        )
    }
}
