//
//  EventListLocalCacheRepository+Sections.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

// Section operations of ``EventListLocalCacheRepository``.
extension EventListLocalCacheRepository {
    func addSection(_ section: ListSection, toListWithIdentifier listIdentifier: String) async throws {
        let builder = builder
        let items = section.items.map(builder.records(for:))
        try await database.transaction { db in
            try Self.requireList(listIdentifier, in: db)
            let position = try ListSectionRecord
                .where { $0.listID.eq(listIdentifier) }
                .fetchAll(db)
                .map(\.position)
                .max()
                .map { $0 + 1 } ?? 0
            let record = ListSectionRecord(id: section.identifier, listID: listIdentifier, title: section.title, position: position)
            try ListSectionRecord.insert { [record] }.execute(db)
            try Self.save(items, in: db)
            let links = items.enumerated().map { index, entry in
                ListItemLinkRecord(sectionID: section.identifier, itemID: entry.item.id, position: index)
            }
            try ListItemLinkRecord.insert { links }.execute(db)
        }
        logger.debug("Added section \(section.identifier) to list \(listIdentifier)")
    }

    func updateSection(_ section: ListSection) async throws {
        try await database.transaction { db in
            guard var record = try ListSectionRecord.find(section.identifier).fetchOne(db) else {
                throw EventListError.sectionNotFound(identifier: section.identifier)
            }
            record.title = section.title
            try ListSectionRecord.update(record).execute(db)
        }
        logger.debug("Updated section \(section.identifier)")
    }

    func deleteSection(identifier: String) async throws {
        // Links cascade; items are never touched.
        try await database.delete(ListSectionRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted section \(identifier)")
    }
}
