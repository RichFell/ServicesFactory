//
//  SQLiteDatabase+Migrations.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

extension SQLiteDatabase.Migration {
    /// Every schema migration, in the order it must run. This is the default for ``SQLiteDatabase``.
    ///
    /// To change the schema later, add a new migration below and **append** it here. Never edit
    /// or reorder a migration that has shipped: databases that already ran it will not run it
    /// again, so the change would only reach new installs. Identifiers must be unique and stable.
    static let all: [SQLiteDatabase.Migration] = [
        .createListTables,
        .createEventTables,
        .createListItemLinks,
        .createEventRuns
    ]

    /// Makes events reusable by moving completion state onto per-run snapshots.
    ///
    /// Creates `eventRuns` and the snapshot tables (`eventRunLists`, `eventRunListFields`,
    /// `eventRunItems`) plus `eventRunCompletedItems`. Each existing event becomes one run with the
    /// same identifier, carrying its completion state and a copy of its lists as they are now. The
    /// legacy `eventCompletedItems` table and `events.isComplete` column are then removed. Runs copy
    /// their content, so later list edits and item deletions never reach them. Relies on GRDB
    /// disabling foreign key enforcement while a migration runs.
    static let createEventRuns = SQLiteDatabase.Migration(identifier: "create-event-runs") { db in
        try createRunTables(in: db)
        try copyEventsIntoRuns(in: db)
        try dropLegacyEventState(in: db)
    }

    private static func createRunTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "eventRuns" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "eventID" TEXT NOT NULL REFERENCES "events"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL,
                "isComplete" INTEGER NOT NULL,
                "startedAt" REAL NOT NULL,
                "completedAt" REAL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventRunLists" (
                "runID" TEXT NOT NULL REFERENCES "eventRuns"("id") ON DELETE CASCADE,
                "listID" TEXT NOT NULL,
                "title" TEXT NOT NULL,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("runID", "listID")
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventRunListFields" (
                "runID" TEXT NOT NULL,
                "listID" TEXT NOT NULL,
                "field" TEXT NOT NULL,
                PRIMARY KEY ("runID", "listID", "field"),
                FOREIGN KEY ("runID", "listID") REFERENCES "eventRunLists"("runID", "listID") ON DELETE CASCADE
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventRunItems" (
                "runID" TEXT NOT NULL,
                "listID" TEXT NOT NULL,
                "itemID" TEXT NOT NULL,
                "name" TEXT NOT NULL,
                "weightInGrams" REAL,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("runID", "listID", "itemID"),
                FOREIGN KEY ("runID", "listID") REFERENCES "eventRunLists"("runID", "listID") ON DELETE CASCADE
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventRunCompletedItems" (
                "runID" TEXT NOT NULL REFERENCES "eventRuns"("id") ON DELETE CASCADE,
                "itemID" TEXT NOT NULL,
                PRIMARY KEY ("runID", "itemID")
            )
            """)
    }

    /// Turns every event into one run (same identifier) with a snapshot of its current lists.
    private static func copyEventsIntoRuns(in db: Database) throws {
        let now = "CAST(strftime('%s', 'now') AS REAL)"
        try db.execute(sql: """
            INSERT INTO "eventRuns" ("id", "eventID", "title", "isComplete", "startedAt", "completedAt")
            SELECT "id", "id", "title", "isComplete", \(now), CASE "isComplete" WHEN 1 THEN \(now) END
            FROM "events"
            """)
        try db.execute(sql: """
            INSERT INTO "eventRunLists" ("runID", "listID", "title", "position")
            SELECT el."eventID", l."id", l."title", el."position"
            FROM "eventLists" el JOIN "lists" l ON l."id" = el."listID"
            """)
        try db.execute(sql: """
            INSERT INTO "eventRunListFields" ("runID", "listID", "field")
            SELECT el."eventID", lf."listID", lf."field"
            FROM "eventLists" el JOIN "listFields" lf ON lf."listID" = el."listID"
            """)
        try db.execute(sql: """
            INSERT INTO "eventRunItems" ("runID", "listID", "itemID", "name", "weightInGrams", "position")
            SELECT el."eventID", k."listID", i."id", i."name", i."weightInGrams", k."position"
            FROM "eventLists" el
            JOIN "listItemLinks" k ON k."listID" = el."listID"
            JOIN "listItems" i ON i."id" = k."itemID"
            """)
        try db.execute(sql: """
            INSERT INTO "eventRunCompletedItems" ("runID", "itemID")
            SELECT "eventID", "itemID" FROM "eventCompletedItems"
            """)
    }

    /// Drops `eventCompletedItems` and rebuilds `events` without `isComplete`.
    private static func dropLegacyEventState(in db: Database) throws {
        try db.execute(sql: #"DROP TABLE "eventCompletedItems""#)
        try db.execute(sql: """
            CREATE TABLE "eventsNew" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "title" TEXT NOT NULL
            )
            """)
        try db.execute(sql: #"INSERT INTO "eventsNew" ("id", "title") SELECT "id", "title" FROM "events""#)
        try db.execute(sql: #"DROP TABLE "events""#)
        try db.execute(sql: #"ALTER TABLE "eventsNew" RENAME TO "events""#)
    }

    /// Makes items standalone so one item can belong to many lists.
    ///
    /// Creates `listItemLinks` (list, item, position), copies each existing item's `listID` and
    /// `position` into it, then rebuilds `listItems` without those two columns. Deleting a list
    /// cascades to its links only, so the items survive. Relies on GRDB disabling foreign key
    /// enforcement while a migration runs, which makes dropping the old `listItems` safe.
    static let createListItemLinks = SQLiteDatabase.Migration(identifier: "create-list-item-links") { db in
        try db.execute(sql: """
            CREATE TABLE "listItemLinks" (
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "itemID" TEXT NOT NULL REFERENCES "listItems"("id") ON DELETE CASCADE,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("listID", "itemID")
            )
            """)
        try db.execute(sql: """
            INSERT INTO "listItemLinks" ("listID", "itemID", "position")
            SELECT "listID", "id", "position" FROM "listItems"
            """)
        try db.execute(sql: """
            CREATE TABLE "listItemsNew" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "name" TEXT NOT NULL,
                "weightInGrams" REAL
            )
            """)
        try db.execute(sql: """
            INSERT INTO "listItemsNew" ("id", "name", "weightInGrams")
            SELECT "id", "name", "weightInGrams" FROM "listItems"
            """)
        try db.execute(sql: #"DROP TABLE "listItems""#)
        try db.execute(sql: #"ALTER TABLE "listItemsNew" RENAME TO "listItems""#)
        try db.execute(sql: #"CREATE INDEX "listItemLinks_itemID" ON "listItemLinks"("itemID")"#)
    }

    /// Creates the `events`, `eventLists` and `eventCompletedItems` tables backing ``EventRecord``,
    /// ``EventListRecord`` and ``EventCompletedItemRecord``.
    static let createEventTables = SQLiteDatabase.Migration(identifier: "create-event-tables") { db in
        try db.execute(sql: """
            CREATE TABLE "events" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "title" TEXT NOT NULL,
                "isComplete" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventLists" (
                "eventID" TEXT NOT NULL REFERENCES "events"("id") ON DELETE CASCADE,
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("eventID", "listID")
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventCompletedItems" (
                "eventID" TEXT NOT NULL REFERENCES "events"("id") ON DELETE CASCADE,
                "itemID" TEXT NOT NULL,
                PRIMARY KEY ("eventID", "itemID")
            )
            """)
    }

    /// Creates the `lists`, `listFields` and `listItems` tables backing ``ListRecord``,
    /// ``ListFieldRecord`` and ``ListItemRecord``.
    static let createListTables = SQLiteDatabase.Migration(identifier: "create-list-tables") { db in
        try db.execute(sql: """
            CREATE TABLE "lists" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "title" TEXT NOT NULL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "listFields" (
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "field" TEXT NOT NULL,
                PRIMARY KEY ("listID", "field")
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "listItems" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "name" TEXT NOT NULL,
                "weightInGrams" REAL,
                "position" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: #"CREATE INDEX "listItems_listID" ON "listItems"("listID")"#)
    }
}
