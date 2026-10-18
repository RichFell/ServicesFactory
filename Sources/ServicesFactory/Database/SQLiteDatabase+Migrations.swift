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
    /// The app has not shipped, so there is a single migration that creates the whole schema.
    /// Once a version ships, never edit or reorder a migration: databases that already ran it will
    /// not run it again, so a change would only reach new installs. Add a new migration below and
    /// **append** it here instead. Identifiers must be unique and stable.
    static let all: [SQLiteDatabase.Migration] = [
        .createInitialSchema
    ]

    /// Creates every table: lists, sections, items and their values, events, and runs.
    static let createInitialSchema = SQLiteDatabase.Migration(identifier: "create-initial-schema") { db in
        try createListTables(in: db)
        try createItemTables(in: db)
        try createEventTables(in: db)
        try createRunTables(in: db)
    }

    /// `lists`, `listFields` and `listSections`, backing ``ListRecord``, ``ListFieldRecord`` and ``ListSectionRecord``.
    private static func createListTables(in db: Database) throws {
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
            CREATE TABLE "listSections" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL,
                "position" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: #"CREATE INDEX "listSections_listID" ON "listSections"("listID")"#)
    }

    /// `listItems`, `listItemValues` and `listItemLinks`, backing ``ListItemRecord``, ``ListItemValueRecord``
    /// and ``ListItemLinkRecord``. Items are standalone; links place them in sections, so one item can be shared.
    private static func createItemTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "listItems" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "name" TEXT NOT NULL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "listItemValues" (
                "itemID" TEXT NOT NULL REFERENCES "listItems"("id") ON DELETE CASCADE,
                "field" TEXT NOT NULL,
                "value" TEXT NOT NULL,
                PRIMARY KEY ("itemID", "field")
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "listItemLinks" (
                "sectionID" TEXT NOT NULL REFERENCES "listSections"("id") ON DELETE CASCADE,
                "itemID" TEXT NOT NULL REFERENCES "listItems"("id") ON DELETE CASCADE,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("sectionID", "itemID")
            )
            """)
        try db.execute(sql: #"CREATE INDEX "listItemLinks_itemID" ON "listItemLinks"("itemID")"#)
    }

    /// `events` and `eventLists`, backing ``EventRecord`` and ``EventListRecord``.
    private static func createEventTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "events" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "title" TEXT NOT NULL
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
    }

    /// `eventRuns` and `eventRunCompletedItems`, backing ``EventRunRecord`` and ``EventRunCompletedItemRecord``.
    ///
    /// A run is self-contained: `snapshot` holds its lists as JSON and `eventID` has no foreign key,
    /// so a run outlives its event and any later edit to the live lists.
    private static func createRunTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "eventRuns" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "eventID" TEXT NOT NULL,
                "title" TEXT NOT NULL,
                "isComplete" INTEGER NOT NULL,
                "startedAt" REAL NOT NULL,
                "completedAt" REAL,
                "snapshot" TEXT NOT NULL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "eventRunCompletedItems" (
                "runID" TEXT NOT NULL REFERENCES "eventRuns"("id") ON DELETE CASCADE,
                "listID" TEXT NOT NULL,
                "itemID" TEXT NOT NULL,
                PRIMARY KEY ("runID", "listID", "itemID")
            )
            """)
    }
}
