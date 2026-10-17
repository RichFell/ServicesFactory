//
//  ListItemLinksMigrationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData
import Testing
@testable import ServicesFactory

struct ListItemLinksMigrationTests {
    private func migrate(_ queue: DatabaseQueue, with migrations: [SQLiteDatabase.Migration]) throws {
        var migrator = DatabaseMigrator()
        for migration in migrations {
            migrator.registerMigration(migration.identifier, migrate: migration.run)
        }
        try migrator.migrate(queue)
    }

    /// Builds a database at the pre-link schema holding one list with two items.
    private func makeLegacyDatabase() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try migrate(queue, with: [.createListTables, .createEventTables])
        try queue.write { db in
            try db.execute(sql: #"INSERT INTO "lists" VALUES ('l', 'List')"#)
            try db.execute(sql: """
                INSERT INTO "listItems" ("id", "listID", "name", "weightInGrams", "position")
                VALUES ('a', 'l', 'A', NULL, 1), ('b', 'l', 'B', 5, 0)
                """)
        }
        return queue
    }

    @Test func existingItemsBecomeOrderedLinks() throws {
        let queue = try makeLegacyDatabase()

        try migrate(queue, with: SQLiteDatabase.Migration.all)

        let (linked, weight, columns) = try queue.read { db in
            (
                try String.fetchAll(
                    db,
                    sql: #"SELECT "itemID" FROM "listItemLinks" WHERE "listID" = 'l' ORDER BY "position""#
                ),
                try Double.fetchOne(db, sql: #"SELECT "weightInGrams" FROM "listItems" WHERE "id" = 'b'"#),
                try db.columns(in: "listItems").map(\.name)
            )
        }

        #expect(linked == ["b", "a"])
        #expect(weight == 5)
        #expect(columns == ["id", "name", "weightInGrams"])
    }

    @Test func deletingAListKeepsItsItems() throws {
        let queue = try makeLegacyDatabase()
        try migrate(queue, with: SQLiteDatabase.Migration.all)

        try queue.write { db in
            try db.execute(sql: #"DELETE FROM "lists""#)
        }

        let (items, links) = try queue.read { db in
            (
                try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "listItems""#),
                try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "listItemLinks""#)
            )
        }

        #expect(items == 2)
        #expect(links == 0)
    }
}
