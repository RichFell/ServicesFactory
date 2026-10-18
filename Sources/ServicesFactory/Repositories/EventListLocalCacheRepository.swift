//
//  EventListLocalCacheRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import OSLog
import SQLiteData

/// An ``EventListWritableRepository`` backed by a local ``SQLiteDatabase``.
///
/// Speaks in public ``List`` models with its service; the stored record types stay
/// internal and are mapped by an ``EventListRecordBuilder``. Every write runs in one
/// transaction, so a failure leaves the database unchanged.
final class EventListLocalCacheRepository: EventListWritableRepository {
    let logger = Logger(subsystem: "ServicesFactory", category: "EventListLocalCacheRepository")

    let database: SQLiteDatabase
    let builder: EventListRecordBuilder

    init(
        database: SQLiteDatabase,
        builder: EventListRecordBuilder = EventListRecordBuilder()
    ) {
        self.database = database
        self.builder = builder
    }

    // MARK: - Read

    func allLists() -> AsyncThrowingStream<[List], any Error> {
        database.observe { db in
            let lists = try self.fetchLists(in: db)
            self.logger.debug("Loaded \(lists.count) cached list(s)")
            return lists
        }
    }

    func allEvents() -> AsyncThrowingStream<[Event], any Error> {
        database.observe { db in
            let events = try EventRecord.fetchAll(db)
            let eventLists = try EventListRecord.fetchAll(db)
            let lists = try self.fetchLists(in: db)
            self.logger.debug("Loaded \(events.count) cached event(s)")
            return self.builder.events(
                from: events,
                lists: lists,
                eventLists: eventLists
            )
        }
    }

    // MARK: - Lists

    /// Caches `lists`, replacing any stored list with the same identifier.
    ///
    /// Replaced lists lose their old sections and links, but the items they linked are kept.
    func store(_ lists: [List]) async throws {
        let ids = lists.map(\.identifier)
        let records = lists.map(builder.records(for:))
        try await database.transaction { db in
            // Fields, sections and links cascade.
            try ListRecord.where { $0.id.in(ids) }.delete().execute(db)
            try Self.insert(records, in: db)
        }
        logger.debug("Cached \(lists.count) list(s)")
    }

    func createList(_ list: List) async throws {
        let records = builder.records(for: list)
        try await database.transaction { db in
            try Self.insert([records], in: db)
        }
        logger.debug("Created list \(list.identifier) with \(list.sections.count) section(s)")
    }

    func updateList(_ list: List) async throws {
        let record = ListRecord(list)
        let fields = ListFieldRecord.records(for: list)
        try await database.transaction { db in
            try Self.requireList(record.id, in: db)
            try ListRecord.update(record).execute(db)
            try ListFieldRecord.where { $0.listID.eq(record.id) }.delete().execute(db)
            try ListFieldRecord.insert { fields }.execute(db)
        }
        logger.debug("Updated list \(list.identifier)")
    }

    func deleteList(identifier: String) async throws {
        // Fields, sections, links and event membership cascade; items are never touched.
        try await database.delete(ListRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted list \(identifier)")
    }

    // MARK: - Items

    func addItem(_ item: ListItem, toSectionWithIdentifier sectionIdentifier: String) async throws {
        let records = builder.records(for: item)
        try await database.transaction { db in
            try Self.requireSection(sectionIdentifier, in: db)
            try Self.save([records], in: db)
            let links = try Self.links(inSection: sectionIdentifier, in: db)
            guard !links.contains(where: { $0.itemID == records.item.id }) else { return }
            let position = (links.map(\.position).max() ?? -1) + 1
            let link = ListItemLinkRecord(sectionID: sectionIdentifier, itemID: records.item.id, position: position)
            try ListItemLinkRecord.insert { [link] }.execute(db)
        }
        logger.debug("Added item \(item.identifier) to section \(sectionIdentifier)")
    }

    func removeItem(identifier: String, fromSectionWithIdentifier sectionIdentifier: String) async throws {
        try await database.delete(ListItemLinkRecord.self) {
            $0.sectionID.eq(sectionIdentifier) && $0.itemID.eq(identifier)
        }
        logger.debug("Removed item \(identifier) from section \(sectionIdentifier)")
    }

    func updateItem(_ item: ListItem) async throws {
        let records = builder.records(for: item)
        try await database.transaction { db in
            guard try ListItemRecord.find(records.item.id).fetchOne(db) != nil else {
                throw EventListError.itemNotFound(identifier: records.item.id)
            }
            try Self.save([records], in: db)
        }
        logger.debug("Updated item \(item.identifier)")
    }

    func deleteItem(identifier: String) async throws {
        // Values and links cascade. Runs hold their own copy of the item, so they are left untouched.
        try await database.delete(ListItemRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted item \(identifier)")
    }

    func moveItem(
        identifier: String,
        inSectionWithIdentifier sectionIdentifier: String,
        to position: Int
    ) async throws {
        try await database.transaction { db in
            try Self.requireSection(sectionIdentifier, in: db)
            let links = try Self.links(inSection: sectionIdentifier, in: db)
            guard links.contains(where: { $0.itemID == identifier }) else {
                throw EventListError.itemNotFound(identifier: identifier)
            }
            let moved = ListItemLinkRecord.moving(identifier, to: position, in: links)
            try ListItemLinkRecord.where { $0.sectionID.eq(sectionIdentifier) }.delete().execute(db)
            try ListItemLinkRecord.insert { moved }.execute(db)
        }
        logger.debug("Moved item \(identifier) to position \(position) in section \(sectionIdentifier)")
    }

    // MARK: - Helpers

    /// Every stored list, built from its rows in a single read.
    func fetchLists(in db: Database) throws -> [List] {
        builder.lists(
            from: try ListRecord.fetchAll(db),
            fields: try ListFieldRecord.fetchAll(db),
            sections: try ListSectionRecord.fetchAll(db),
            items: try ListItemRecord.fetchAll(db),
            values: try ListItemValueRecord.fetchAll(db),
            links: try ListItemLinkRecord.fetchAll(db)
        )
    }

    /// Inserts each list's rows. Items that already exist are updated rather than duplicated.
    static func insert(_ records: [EventListRecordBuilder.ListRecords], in db: Database) throws {
        try ListRecord.insert { records.map(\.list) }.execute(db)
        try ListFieldRecord.insert { records.flatMap(\.fields) }.execute(db)
        try ListSectionRecord.insert { records.flatMap(\.sections) }.execute(db)
        try save(records.flatMap(\.items), in: db)
        try ListItemLinkRecord.insert { records.flatMap(\.links) }.execute(db)
    }

    /// Inserts each item, or updates it when a row with the same identifier exists, replacing its values.
    static func save(_ items: [EventListRecordBuilder.ItemRecords], in db: Database) throws {
        for entry in items {
            if try ListItemRecord.find(entry.item.id).fetchOne(db) == nil {
                try ListItemRecord.insert { [entry.item] }.execute(db)
            } else {
                try ListItemRecord.update(entry.item).execute(db)
            }
            try ListItemValueRecord.where { $0.itemID.eq(entry.item.id) }.delete().execute(db)
            try ListItemValueRecord.insert { entry.values }.execute(db)
        }
    }

    /// The links of `sectionID`, in display order.
    static func links(inSection sectionID: String, in db: Database) throws -> [ListItemLinkRecord] {
        try ListItemLinkRecord
            .where { $0.sectionID.eq(sectionID) }
            .fetchAll(db)
            .sorted { $0.position < $1.position }
    }

    static func requireList(_ identifier: String, in db: Database) throws {
        guard try ListRecord.find(identifier).fetchOne(db) != nil else {
            throw EventListError.listNotFound(identifier: identifier)
        }
    }

    static func requireSection(_ identifier: String, in db: Database) throws {
        guard try ListSectionRecord.find(identifier).fetchOne(db) != nil else {
            throw EventListError.sectionNotFound(identifier: identifier)
        }
    }
}
