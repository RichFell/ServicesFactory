//
//  EventRunsMigrationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

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

    @Test func existingEventBecomesACompletedRunWithASnapshot() throws {
        let queue = try makeLegacyDatabase()

        try migrate(queue, with: SQLiteDatabase.Migration.all)

        let (eventID, isComplete, completedAt, fields, items, completed) = try queue.read { db in
            (
                try String.fetchOne(db, sql: #"SELECT "eventID" FROM "eventRuns" WHERE "id" = 'e'"#),
                try Int.fetchOne(db, sql: #"SELECT "isComplete" FROM "eventRuns" WHERE "id" = 'e'"#),
                try Double.fetchOne(db, sql: #"SELECT "completedAt" FROM "eventRuns" WHERE "id" = 'e'"#),
                try String.fetchAll(db, sql: #"SELECT "field" FROM "eventRunListFields" WHERE "runID" = 'e'"#),
                try String.fetchAll(db, sql: #"SELECT "itemID" FROM "eventRunItems" WHERE "runID" = 'e' ORDER BY "position""#),
                try String.fetchAll(db, sql: #"SELECT "itemID" FROM "eventRunCompletedItems" WHERE "runID" = 'e'"#)
            )
        }

        #expect(eventID == "e")
        #expect(isComplete == 1)
        #expect(completedAt != nil)
        #expect(fields == ["weight"])
        #expect(items == ["b", "a"])
        #expect(completed == ["a"])
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
