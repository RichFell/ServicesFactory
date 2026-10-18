//
//  EventRunsMigrationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import class GRDB.Row
import SQLiteData
import Testing
@testable import ServicesFactory

struct EventRunsMigrationTests {
    private func migrate(_ queue: DatabaseQueue, with migrations: [SQLiteDatabase.Migration]) throws {
        var migrator = DatabaseMigrator()
        for migration in migrations {
            migrator.registerMigration(migration.identifier, migrate: migration.run)
        }
        try migrator.migrate(queue)
    }

    /// Builds a database at the pre-run schema: one complete event using one list with two items.
    private func makeLegacyDatabase() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try migrate(queue, with: [.createListTables, .createEventTables, .createListItemLinks])
        try queue.write { db in
            try db.execute(sql: #"INSERT INTO "lists" VALUES ('l', 'List')"#)
            try db.execute(sql: #"INSERT INTO "listFields" VALUES ('l', 'weight')"#)
            try db.execute(sql: #"INSERT INTO "listItems" VALUES ('a', 'A', NULL), ('b', 'B', 5)"#)
            try db.execute(sql: #"INSERT INTO "listItemLinks" VALUES ('l', 'b', 0), ('l', 'a', 1)"#)
            try db.execute(sql: #"INSERT INTO "events" VALUES ('e', 'Event', 1)"#)
            try db.execute(sql: #"INSERT INTO "eventLists" VALUES ('e', 'l', 0)"#)
            try db.execute(sql: #"INSERT INTO "eventCompletedItems" VALUES ('e', 'a')"#)
        }
        return queue
    }

    @Test func existingEventBecomesACompletedRunWithAJSONSnapshot() throws {
        let queue = try makeLegacyDatabase()

        try migrate(queue, with: SQLiteDatabase.Migration.all)

        let (eventID, isComplete, completedAt, snapshot, completed, legacyTables) = try queue.read { db in
            (
                try String.fetchOne(db, sql: #"SELECT "eventID" FROM "eventRuns" WHERE "id" = 'e'"#),
                try Int.fetchOne(db, sql: #"SELECT "isComplete" FROM "eventRuns" WHERE "id" = 'e'"#),
                try Double.fetchOne(db, sql: #"SELECT "completedAt" FROM "eventRuns" WHERE "id" = 'e'"#),
                try String.fetchOne(db, sql: #"SELECT "snapshot" FROM "eventRuns" WHERE "id" = 'e'"#),
                try Row.fetchAll(db, sql: #"SELECT "listID", "itemID" FROM "eventRunCompletedItems" WHERE "runID" = 'e'"#)
                    .map { "\($0["listID"] as String):\($0["itemID"] as String)" },
                try ["eventRunLists", "eventRunListFields", "eventRunItems"].filter { try db.tableExists($0) }
            )
        }
        let lists = try EventRunSnapshot.decode(json: try #require(snapshot)).makeLists()

        #expect(eventID == "e")
        #expect(isComplete == 1)
        #expect(completedAt != nil)
        #expect(lists.map(\.identifier) == ["l"])
        #expect(lists[0].title == "List")
        #expect(lists[0].fields == [.weight])
        #expect(lists[0].items.map(\.identifier) == ["b", "a"])
        #expect(lists[0].items[0].weight == Measurement(value: 5, unit: .grams))
        #expect(completed == ["l:a"])
        #expect(legacyTables.isEmpty)
    }

    @Test func runsSurviveDeletingTheirEvent() throws {
        let queue = try makeLegacyDatabase()
        try migrate(queue, with: SQLiteDatabase.Migration.all)

        try queue.write { db in
            try db.execute(sql: #"DELETE FROM "events""#)
        }

        let runs = try queue.read { db in
            try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "eventRuns""#)
        }
        #expect(runs == 1)
    }

    @Test func eventsLoseTheirCompletionColumnAndKeepTheirLists() throws {
        let queue = try makeLegacyDatabase()

        try migrate(queue, with: SQLiteDatabase.Migration.all)

        let (columns, lists, legacyTable) = try queue.read { db in
            (
                try db.columns(in: "events").map(\.name),
                try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "eventLists""#),
                try db.tableExists("eventCompletedItems")
            )
        }
        #expect(columns == ["id", "title"])
        #expect(lists == 1)
        #expect(!legacyTable)
    }
}
