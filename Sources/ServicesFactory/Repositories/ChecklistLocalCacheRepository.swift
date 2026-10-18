//
//  ChecklistLocalCacheRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import OSLog
import SQLiteData

/// A ``ChecklistWritableRepository`` backed by a local ``SQLiteDatabase``.
///
/// Speaks in public ``Checklist`` models with its service; the stored record types stay
/// internal and are mapped by a ``ChecklistRecordBuilder``. Every write runs in one
/// transaction, so a failure leaves the database unchanged.
final class ChecklistLocalCacheRepository: ChecklistWritableRepository {
    let logger = Logger(subsystem: "ServicesFactory", category: "ChecklistLocalCacheRepository")

    let database: SQLiteDatabase
    let builder: ChecklistRecordBuilder

    init(
        database: SQLiteDatabase,
        builder: ChecklistRecordBuilder = ChecklistRecordBuilder()
    ) {
        self.database = database
        self.builder = builder
    }

    // MARK: - Read

    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error> {
        database.observe { db in
            let checklists = try self.fetchChecklists(in: db)
            self.logger.debug("Loaded \(checklists.count) cached checklist(s)")
            return checklists
        }
    }

    // MARK: - Checklists

    /// Caches `checklists`, replacing any stored checklist with the same identifier.
    func store(_ checklists: [Checklist]) async throws {
        let ids = checklists.map(\.identifier)
        let records = checklists.map(builder.records(for:))
        try await database.transaction { db in
            // Components and items cascade.
            try ChecklistRecord.where { $0.id.in(ids) }.delete().execute(db)
            for entry in records {
                try Self.insert(entry, in: db)
            }
        }
        logger.debug("Cached \(checklists.count) checklist(s)")
    }

    func createChecklist(_ checklist: Checklist) async throws {
        try Self.requireValidFlatList(checklist)
        let records = builder.records(for: checklist)
        try await database.transaction { db in
            try Self.insert(records, in: db)
        }
        logger.debug("Created checklist \(checklist.identifier) with \(checklist.components.count) component(s)")
    }

    func updateChecklist(_ checklist: Checklist) async throws {
        let record = ChecklistRecord(checklist)
        try await database.transaction { db in
            try Self.requireChecklist(record.id, in: db)
            if record.isFlatList {
                let count = try ChecklistComponentRecord.where { $0.checklistID.eq(record.id) }.fetchAll(db).count
                guard count == 1 else {
                    throw ChecklistError.flatChecklistRequiresOneComponent(identifier: record.id)
                }
            }
            try ChecklistRecord.update(record).execute(db)
        }
        logger.debug("Updated checklist \(checklist.identifier)")
    }

    func deleteChecklist(identifier: String) async throws {
        // Components and items cascade.
        try await database.delete(ChecklistRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted checklist \(identifier)")
    }

    func copyChecklist(identifier: String, title: String) async throws -> Checklist {
        let builder = builder
        let copy = try await database.transaction { db in
            guard let original = try self.fetchChecklists(in: db).first(where: { $0.identifier == identifier }) else {
                throw ChecklistError.checklistNotFound(identifier: identifier)
            }
            let copy = builder.copy(of: original, title: title)
            try Self.insert(builder.records(for: copy), in: db)
            return copy
        }
        logger.debug("Copied checklist \(identifier) to \(copy.identifier)")
        return copy
    }

    // MARK: - Items

    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws {
        try await database.transaction { db in
            try Self.requireComponent(componentIdentifier, in: db)
            let position = (try Self.items(inComponent: componentIdentifier, in: db).map(\.position).max() ?? -1) + 1
            let record = ChecklistItemRecord(item, componentID: componentIdentifier, position: position)
            try ChecklistItemRecord.insert { [record] }.execute(db)
        }
        logger.debug("Added item \(item.identifier) to component \(componentIdentifier)")
    }

    func updateItem(_ item: ChecklistItem) async throws {
        try await database.transaction { db in
            guard let existing = try ChecklistItemRecord.find(item.identifier).fetchOne(db) else {
                throw ChecklistError.itemNotFound(identifier: item.identifier)
            }
            let record = ChecklistItemRecord(item, componentID: existing.componentID, position: existing.position)
            try ChecklistItemRecord.update(record).execute(db)
        }
        logger.debug("Updated item \(item.identifier)")
    }

    func setItem(identifier: String, isCompleted: Bool) async throws {
        try await database.transaction { db in
            guard var record = try ChecklistItemRecord.find(identifier).fetchOne(db) else {
                throw ChecklistError.itemNotFound(identifier: identifier)
            }
            record.isCompleted = isCompleted
            try ChecklistItemRecord.update(record).execute(db)
        }
        logger.debug("Set item \(identifier) completed=\(isCompleted)")
    }

    func deleteItem(identifier: String) async throws {
        try await database.delete(ChecklistItemRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted item \(identifier)")
    }

    func moveItem(
        identifier: String,
        inComponentWithIdentifier componentIdentifier: String,
        to position: Int
    ) async throws {
        try await database.transaction { db in
            try Self.requireComponent(componentIdentifier, in: db)
            let items = try Self.items(inComponent: componentIdentifier, in: db)
            guard items.contains(where: { $0.id == identifier }) else {
                throw ChecklistError.itemNotFound(identifier: identifier)
            }
            for moved in ChecklistItemRecord.moving(identifier, to: position, in: items) {
                try ChecklistItemRecord.update(moved).execute(db)
            }
        }
        logger.debug("Moved item \(identifier) to position \(position) in component \(componentIdentifier)")
    }

    // MARK: - Helpers

    /// Every stored checklist, built from its rows in a single read.
    func fetchChecklists(in db: Database) throws -> [Checklist] {
        builder.checklists(
            from: try ChecklistRecord.fetchAll(db),
            components: try ChecklistComponentRecord.fetchAll(db),
            items: try ChecklistItemRecord.fetchAll(db)
        )
    }

    /// Inserts a checklist's rows: the checklist, then its components, then their items.
    static func insert(_ records: ChecklistRecordBuilder.ChecklistRecords, in db: Database) throws {
        try ChecklistRecord.insert { [records.checklist] }.execute(db)
        try ChecklistComponentRecord.insert { records.components }.execute(db)
        try ChecklistItemRecord.insert { records.items }.execute(db)
    }

    /// The items of `componentID`, in display order.
    static func items(inComponent componentID: String, in db: Database) throws -> [ChecklistItemRecord] {
        try ChecklistItemRecord
            .where { $0.componentID.eq(componentID) }
            .fetchAll(db)
            .sorted { $0.position < $1.position }
    }

    /// A flat checklist must hold exactly one component.
    static func requireValidFlatList(_ checklist: Checklist) throws {
        guard !checklist.isFlatList || checklist.components.count == 1 else {
            throw ChecklistError.flatChecklistRequiresOneComponent(identifier: checklist.identifier)
        }
    }

    static func requireChecklist(_ identifier: String, in db: Database) throws {
        guard try ChecklistRecord.find(identifier).fetchOne(db) != nil else {
            throw ChecklistError.checklistNotFound(identifier: identifier)
        }
    }

    static func requireComponent(_ identifier: String, in db: Database) throws {
        guard try ChecklistComponentRecord.find(identifier).fetchOne(db) != nil else {
            throw ChecklistError.componentNotFound(identifier: identifier)
        }
    }
}
