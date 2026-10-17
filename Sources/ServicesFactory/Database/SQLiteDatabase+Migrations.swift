//
//  SQLiteDatabase+Migrations.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

extension SQLiteDatabase.Migration {
    /// Every schema migration, in the order it must run. This is the default for ``SQLiteDatabase``.
    ///
    /// To change the schema later, add a new migration below and **append** it here. Never edit
    /// or reorder a migration that has shipped: databases that already ran it will not run it
    /// again, so the change would only reach new installs. Identifiers must be unique and stable.
    static let all: [SQLiteDatabase.Migration] = [
        .createListTables,
        .createEventTables
    ]

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
