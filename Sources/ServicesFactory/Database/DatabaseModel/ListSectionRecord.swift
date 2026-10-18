//
//  ListSectionRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The stored row for a ``ListSection``. Its items are attached by ``ListItemLinkRecord``.
@Table("listSections")
struct ListSectionRecord: Equatable, Sendable {
    let id: String
    let listID: String
    var title: String
    /// The section's index within its list, preserving order.
    var position: Int

    /// Creates one row per section of `list`, in order.
    static func records(for list: List) -> [ListSectionRecord] {
        list.sections.enumerated().map { index, section in
            ListSectionRecord(id: section.identifier, listID: list.identifier, title: section.title, position: index)
        }
    }
}
