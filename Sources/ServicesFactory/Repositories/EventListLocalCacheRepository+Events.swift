//
//  EventListLocalCacheRepository+Events.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import SQLiteData

// Event and run operations of ``EventListLocalCacheRepository``.
extension EventListLocalCacheRepository {

    // MARK: - Read

    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error> {
        database.observe { db in
            let runs = try self.builder.runs(
                from: EventRunRecord.fetchAll(db),
                completedItems: EventRunCompletedItemRecord.fetchAll(db)
            )
            self.logger.debug("Loaded \(runs.count) cached run(s)")
            return runs
        }
    }

    // MARK: - Events

    func createEvent(_ event: Event) async throws {
        let record = EventRecord(event)
        let joins = EventListRecord.records(for: event)
        try await database.transaction { db in
            try Self.requireLists(joins.map(\.listID), in: db)
            try EventRecord.insert { [record] }.execute(db)
            try EventListRecord.insert { joins }.execute(db)
        }
        logger.debug("Created event \(event.identifier) with \(event.lists.count) list(s)")
    }

    func updateEvent(_ event: Event) async throws {
        let record = EventRecord(event)
        let joins = EventListRecord.records(for: event)
        try await database.transaction { db in
            try Self.requireEvent(record.id, in: db)
            try Self.requireLists(joins.map(\.listID), in: db)
            try EventRecord.update(record).execute(db)
            try EventListRecord.where { $0.eventID.eq(record.id) }.delete().execute(db)
            try EventListRecord.insert { joins }.execute(db)
        }
        logger.debug("Updated event \(event.identifier)")
    }

    func deleteEvent(identifier: String) async throws {
        // Event lists cascade. Runs are self-contained and are kept, as are the live lists.
        try await database.delete(EventRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted event \(identifier)")
    }

    // MARK: - Runs

    func startRun(
        ofEventWithIdentifier eventIdentifier: String,
        identifier: String,
        startedAt: Date
    ) async throws -> EventRun {
        let builder = builder
        let run = try await database.transaction { db in
            guard let event = try EventRecord.find(eventIdentifier).fetchOne(db) else {
                throw EventListError.eventNotFound(identifier: eventIdentifier)
            }
            let joins = try EventListRecord.where { $0.eventID.eq(eventIdentifier) }.fetchAll(db)
            let liveLists = Dictionary(
                try self.fetchLists(in: db).map { ($0.identifier, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let run = EventRun(
                identifier: identifier,
                eventIdentifier: eventIdentifier,
                title: event.title,
                lists: joins.sorted { $0.position < $1.position }.compactMap { liveLists[$0.listID] },
                startedAt: startedAt
            )
            let runRecord = try builder.records(for: run).run
            try EventRunRecord.insert { [runRecord] }.execute(db)
            return run
        }
        logger.debug("Started run \(identifier) of event \(eventIdentifier) with \(run.lists.count) list(s)")
        return run
    }

    func setItem(
        identifier: String,
        isCompleted: Bool,
        inListWithIdentifier listIdentifier: String,
        inRunWithIdentifier runIdentifier: String
    ) async throws {
        try await database.transaction { db in
            try Self.requireSnapshotItem(
                identifier,
                inList: listIdentifier,
                ofRun: runIdentifier,
                in: db
            )
            try EventRunCompletedItemRecord
                .where { $0.runID.eq(runIdentifier) && $0.listID.eq(listIdentifier) && $0.itemID.eq(identifier) }
                .delete()
                .execute(db)
            guard isCompleted else { return }
            let mark = EventRunCompletedItemRecord(runID: runIdentifier, listID: listIdentifier, itemID: identifier)
            try EventRunCompletedItemRecord.insert { [mark] }.execute(db)
        }
        logger.debug("Set item \(identifier) completed=\(isCompleted) in list \(listIdentifier) of run \(runIdentifier)")
    }

    func setRun(
        identifier: String,
        isComplete: Bool,
        at date: Date
    ) async throws {
        try await database.transaction { db in
            guard var record = try EventRunRecord.find(identifier).fetchOne(db) else {
                throw EventListError.runNotFound(identifier: identifier)
            }
            record.isComplete = isComplete
            record.completedAt = isComplete ? date.timeIntervalSince1970 : nil
            try EventRunRecord.update(record).execute(db)
        }
        logger.debug("Set run \(identifier) complete=\(isComplete)")
    }

    func deleteRun(identifier: String) async throws {
        // The completion rows cascade.
        try await database.delete(EventRunRecord.self) { $0.id.eq(identifier) }
        logger.debug("Deleted run \(identifier)")
    }

    // MARK: - Helpers

    private static func requireLists(_ identifiers: [String], in db: Database) throws {
        for identifier in identifiers {
            try requireList(identifier, in: db)
        }
    }

    private static func requireEvent(_ identifier: String, in db: Database) throws {
        guard try EventRecord.find(identifier).fetchOne(db) != nil else {
            throw EventListError.eventNotFound(identifier: identifier)
        }
    }

    /// Checks, against the run's snapshot, that the run, the list in it and the item in that list all exist.
    private static func requireSnapshotItem(
        _ itemIdentifier: String,
        inList listIdentifier: String,
        ofRun runIdentifier: String,
        in db: Database
    ) throws {
        guard let run = try EventRunRecord.find(runIdentifier).fetchOne(db) else {
            throw EventListError.runNotFound(identifier: runIdentifier)
        }
        let lists = try EventRunSnapshot.decode(json: run.snapshot).makeLists()
        guard let list = lists.first(where: { $0.identifier == listIdentifier }) else {
            throw EventListError.listNotFound(identifier: listIdentifier)
        }
        guard list.items.contains(where: { $0.identifier == itemIdentifier }) else {
            throw EventListError.itemNotFound(identifier: itemIdentifier)
        }
    }
}
