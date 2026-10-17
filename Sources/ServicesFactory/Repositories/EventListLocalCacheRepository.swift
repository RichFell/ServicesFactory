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
    private static let logger = Logger(subsystem: "ServicesFactory", category: "EventListLocalCacheRepository")

    private let database: SQLiteDatabase
    private let builder: EventListRecordBuilder

    init(
        database: SQLiteDatabase,
        builder: EventListRecordBuilder = EventListRecordBuilder()
    ) {
        self.database = database
        self.builder = builder
    }

    // MARK: - Read

    func allLists() async throws -> [List] {
        let lists = try await database.fetchAll(ListRecord.self)
        let fields = try await database.fetchAll(ListFieldRecord.self)
        let items = try await database.fetchAll(ListItemRecord.self)
        let links = try await database.fetchAll(ListItemLinkRecord.self)
        Self.logger.debug("Loaded \(lists.count) cached list(s)")
        return builder.lists(from: lists, fields: fields, items: items, links: links)
    }

    func allEvents() async throws -> [Event] {
        let events = try await database.fetchAll(EventRecord.self)
        let eventLists = try await database.fetchAll(EventListRecord.self)
        let completedItems = try await database.fetchAll(EventCompletedItemRecord.self)
        let lists = try await allLists()
        Self.logger.debug("Loaded \(events.count) cached event(s)")
        return builder.events(
            from: events,
            lists: lists,
            eventLists: eventLists,
            completedItems: completedItems
        )
    }

    // MARK: - Lists

    /// Caches `lists`, replacing any stored list with the same identifier.
    ///
    /// Replaced lists lose their old links, but the items they linked are kept.
    func store(_ lists: [List]) async throws {
        let ids = lists.map(\.identifier)
        let records = lists.map(builder.records(for:))
        try await database.transaction { db in
            try ListItemLinkRecord.where { $0.listID.in(ids) }.delete().execute(db)
            try ListFieldRecord.where { $0.listID.in(ids) }.delete().execute(db)
            try ListRecord.where { $0.id.in(ids) }.delete().execute(db)
            try Self.insert(records, in: db)
        }
        Self.logger.debug("Cached \(lists.count) list(s)")
    }

    func createList(_ list: List) async throws {
        let records = builder.records(for: list)
        try await database.transaction { db in
            try Self.insert([records], in: db)
        }
        Self.logger.debug("Created list \(list.identifier) with \(list.items.count) item(s)")
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
        Self.logger.debug("Updated list \(list.identifier)")
    }

    func deleteList(identifier: String) async throws {
        // Fields, links and event membership cascade; items are never touched.
        try await database.delete(ListRecord.self) { $0.id.eq(identifier) }
        Self.logger.debug("Deleted list \(identifier)")
    }

    // MARK: - Items

    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws {
        let record = ListItemRecord(item)
        try await database.transaction { db in
            try Self.requireList(listIdentifier, in: db)
            try Self.save([record], in: db)
            let links = try Self.links(inList: listIdentifier, in: db)
            guard !links.contains(where: { $0.itemID == record.id }) else { return }
            let position = (links.map(\.position).max() ?? -1) + 1
            let link = ListItemLinkRecord(listID: listIdentifier, itemID: record.id, position: position)
            try ListItemLinkRecord.insert { [link] }.execute(db)
        }
        Self.logger.debug("Added item \(item.identifier) to list \(listIdentifier)")
    }

    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws {
        try await database.delete(ListItemLinkRecord.self) {
            $0.listID.eq(listIdentifier) && $0.itemID.eq(identifier)
        }
        Self.logger.debug("Removed item \(identifier) from list \(listIdentifier)")
    }

    func updateItem(_ item: ListItem) async throws {
        let record = ListItemRecord(item)
        try await database.transaction { db in
            guard try ListItemRecord.find(record.id).fetchOne(db) != nil else {
                throw EventListError.itemNotFound(identifier: record.id)
            }
            try ListItemRecord.update(record).execute(db)
        }
        Self.logger.debug("Updated item \(item.identifier)")
    }

    func deleteItem(identifier: String) async throws {
        try await database.transaction { db in
            // Completion marks have no foreign key, so remove them here; links cascade.
            try EventCompletedItemRecord.where { $0.itemID.eq(identifier) }.delete().execute(db)
            try ListItemRecord.where { $0.id.eq(identifier) }.delete().execute(db)
        }
        Self.logger.debug("Deleted item \(identifier)")
    }

    func moveItem(
        identifier: String,
        inListWithIdentifier listIdentifier: String,
        to position: Int
    ) async throws {
        try await database.transaction { db in
            try Self.requireList(listIdentifier, in: db)
            let links = try Self.links(inList: listIdentifier, in: db)
            guard links.contains(where: { $0.itemID == identifier }) else {
                throw EventListError.itemNotFound(identifier: identifier)
            }
            let moved = ListItemLinkRecord.moving(identifier, to: position, in: links)
            try ListItemLinkRecord.where { $0.listID.eq(listIdentifier) }.delete().execute(db)
            try ListItemLinkRecord.insert { moved }.execute(db)
        }
        Self.logger.debug("Moved item \(identifier) to position \(position) in list \(listIdentifier)")
    }

    // MARK: - Helpers

    /// Inserts each list's rows. Items that already exist are updated rather than duplicated.
    private static func insert(_ records: [EventListRecordBuilder.ListRecords], in db: Database) throws {
        try ListRecord.insert { records.map(\.list) }.execute(db)
        try ListFieldRecord.insert { records.flatMap(\.fields) }.execute(db)
        try save(records.flatMap(\.items), in: db)
        try ListItemLinkRecord.insert { records.flatMap(\.links) }.execute(db)
    }

    /// Inserts each item, or updates it when a row with the same identifier exists.
    private static func save(_ items: [ListItemRecord], in db: Database) throws {
        for item in items {
            if try ListItemRecord.find(item.id).fetchOne(db) == nil {
                try ListItemRecord.insert { [item] }.execute(db)
            } else {
                try ListItemRecord.update(item).execute(db)
            }
        }
    }

    /// The links of `listID`, in display order.
    private static func links(inList listID: String, in db: Database) throws -> [ListItemLinkRecord] {
        try ListItemLinkRecord
            .where { $0.listID.eq(listID) }
            .fetchAll(db)
            .sorted { $0.position < $1.position }
    }

    private static func requireList(_ identifier: String, in db: Database) throws {
        guard try ListRecord.find(identifier).fetchOne(db) != nil else {
            throw EventListError.listNotFound(identifier: identifier)
        }
    }
}
