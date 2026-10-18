//
//  ChecklistComponentRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The stored row for a ``ChecklistComponent``. Its items live in ``ChecklistItemRecord``.
@Table("checklistComponents")
struct ChecklistComponentRecord: Equatable, Sendable {
    let id: String
    let checklistID: String
    var title: String
    /// The component's index within its checklist, preserving order.
    var position: Int

    /// Creates one row per component of `checklist`, in order.
    static func records(for checklist: Checklist) -> [ChecklistComponentRecord] {
        checklist.components.enumerated().map { index, component in
            ChecklistComponentRecord(
                id: component.identifier,
                checklistID: checklist.identifier,
                title: component.title,
                position: index
            )
        }
    }
}
