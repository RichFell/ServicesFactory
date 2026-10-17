//
//  ListFieldRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row declaring that a list uses a ``ListField``.
@Table("listFields")
struct ListFieldRecord: Equatable, Sendable {
    let listID: String
    /// The ``ListField`` raw value.
    let field: String

    /// Creates one row per field declared by `list`.
    static func records(for list: List) -> [ListFieldRecord] {
        list.fields.map { ListFieldRecord(listID: list.identifier, field: $0.rawValue) }
    }
}
