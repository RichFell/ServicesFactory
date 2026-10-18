//
//  ListRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for a ``List``. Its fields live in ``ListFieldRecord`` and its sections in ``ListSectionRecord``.
@Table("lists")
struct ListRecord: Equatable, Sendable {
    let id: String
    var title: String

    /// Creates a row from a public ``List``.
    init(_ list: List) {
        id = list.identifier
        title = list.title
    }

    /// Rebuilds the public ``List`` from this row, its field rows and its already ordered `sections`.
    func makeList(fields: [ListFieldRecord], sections: [ListSection]) -> List {
        List(
            identifier: id,
            title: title,
            fields: Set(fields.compactMap { ListField(rawValue: $0.field) }),
            sections: sections
        )
    }
}
