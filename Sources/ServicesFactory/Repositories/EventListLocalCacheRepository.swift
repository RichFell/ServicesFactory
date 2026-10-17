//
//  EventListLocalCacheRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import OSLog

/// An ``EventListRepository`` backed by a local ``SQLiteDatabase``.
///
/// Speaks in public ``List`` models with its service; the stored record types stay
/// internal and are mapped by an ``EventListRecordBuilder``.
final class EventListLocalCacheRepository: EventListRepository {
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

    func allLists() async throws -> [List] {
        let lists = try await database.fetchAll(ListRecord.self)
        let fields = try await database.fetchAll(ListFieldRecord.self)
        let items = try await database.fetchAll(ListItemRecord.self)
        Self.logger.debug("Loaded \(lists.count) cached list(s)")
        return builder.lists(from: lists, fields: fields, items: items)
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

    /// Caches `lists`,replacing any stored list with the same identifier.
    func store(_ lists: [List]) async throws {
        let incoming = Set(lists.map(\.identifier))
        try await removeStoredRows(forListIDs: incoming)

        let records = lists.map(builder.records(for:))
        try await database.insert(records.map(\.list))
        try await database.insert(records.flatMap(\.fields))
        try await database.insert(records.flatMap(\.items))
        Self.logger.debug("Cached \(lists.count) list(s)")
    }

    /// Deletes the list, field and item rows belonging to `listIDs`.
    private func removeStoredRows(forListIDs listIDs: Set<String>) async throws {
        let ids = Array(listIDs)
        try await database.delete(ListItemRecord.self) { $0.listID.in(ids) }
        try await database.delete(ListFieldRecord.self) { $0.listID.in(ids) }
        try await database.delete(ListRecord.self) { $0.id.in(ids) }
    }
}
