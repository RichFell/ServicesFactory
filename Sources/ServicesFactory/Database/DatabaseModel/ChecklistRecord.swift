//
//  ChecklistRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for a ``Checklist``. Its components live in ``ChecklistComponentRecord``.
@Table("checklists")
struct ChecklistRecord: Equatable, Sendable {
    let id: String
    var title: String
    /// The ``ChecklistType`` raw value.
    var type: String
    var isFlatList: Bool

    /// Creates a row from a public ``Checklist``.
    init(_ checklist: Checklist) {
        id = checklist.identifier
        title = checklist.title
        type = checklist.type.rawValue
        isFlatList = checklist.isFlatList
    }

    /// Rebuilds the public ``Checklist`` from this row and its already ordered `components`.
    ///
    /// An unknown stored type, such as one written by a newer version, falls back to ``ChecklistType/standard``.
    func makeChecklist(components: [ChecklistComponent]) -> Checklist {
        Checklist(
            identifier: id,
            title: title,
            type: ChecklistType(rawValue: type) ?? .standard,
            isFlatList: isFlatList,
            components: components
        )
    }
}
