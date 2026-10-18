//
//  EventRunSnapshot.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// The lists of an ``EventRun`` as they were when it started, encoded as one JSON document.
///
/// A run never queries inside its snapshot, so storing it whole keeps the live list schema and the
/// run history independent: new list fields and values need no run migration. Unknown fields and
/// values from newer versions are skipped when rebuilding lists.
struct EventRunSnapshot: Codable, Sendable {
    let lists: [ListSnapshot]

    /// Captures `lists`.
    init(lists: [List]) {
        self.lists = lists.map(ListSnapshot.init)
    }

    /// Rebuilds the public lists.
    func makeLists() -> [List] {
        lists.map(\.model)
    }

    /// The snapshot as a JSON string.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    /// Decodes a snapshot from `json`.
    static func decode(json: String) throws -> EventRunSnapshot {
        try JSONDecoder().decode(EventRunSnapshot.self, from: Data(json.utf8))
    }

    // MARK: - Nested Types

    struct ListSnapshot: Codable, Sendable {
        let identifier: String
        let title: String
        let fields: [String]
        let sections: [SectionSnapshot]

        init(_ list: List) {
            identifier = list.identifier
            title = list.title
            fields = list.fields.map(\.rawValue).sorted()
            sections = list.sections.map(SectionSnapshot.init)
        }

        var model: List {
            List(
                identifier: identifier,
                title: title,
                fields: Set(fields.compactMap(ListField.init(rawValue:))),
                sections: sections.map(\.model)
            )
        }
    }

    struct SectionSnapshot: Codable, Sendable {
        let identifier: String
        let title: String
        let items: [ItemSnapshot]

        init(_ section: ListSection) {
            identifier = section.identifier
            title = section.title
            items = section.items.map(ItemSnapshot.init)
        }

        var model: ListSection {
            ListSection(identifier: identifier, title: title, items: items.map(\.model))
        }
    }

    struct ItemSnapshot: Codable, Sendable {
        let identifier: String
        let name: String
        /// Stored values by ``ListField`` raw value.
        let values: [String: String]

        init(_ item: ListItem) {
            identifier = item.identifier
            name = item.name
            values = Dictionary(
                uniqueKeysWithValues: item.values.map { ($0.key.rawValue, $0.value.storedValue) }
            )
        }

        var model: ListItem {
            let pairs = values.compactMap { key, stored -> (ListField, ListFieldValue)? in
                guard
                    let field = ListField(rawValue: key),
                    let value = ListFieldValue(field: field, storedValue: stored)
                else { return nil }
                return (field, value)
            }
            return ListItem(identifier: identifier, name: name, values: Dictionary(uniqueKeysWithValues: pairs))
        }
    }
}
