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

    /// Creates `checklists`, `checklistComponents` and `checklistItems`, backing ``ChecklistRecord``,
    /// ``ChecklistComponentRecord`` and ``ChecklistItemRecord``.
    ///
    /// Each row is owned by its parent and deleting a parent cascades to its children. Nothing is shared
    /// between checklists: reusing one copies its rows.
    static let createInitialSchema = SQLiteDatabase.Migration(identifier: "create-initial-schema") { db in
        try db.execute(sql: """
            CREATE TABLE "checklists" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "title" TEXT NOT NULL,
                "type" TEXT NOT NULL,
                "isFlatList" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: """
            CREATE TABLE "checklistComponents" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "checklistID" TEXT NOT NULL REFERENCES "checklists"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL,
                "position" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: #"CREATE INDEX "checklistComponents_checklistID" ON "checklistComponents"("checklistID")"#)
        try db.execute(sql: """
            CREATE TABLE "checklistItems" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "componentID" TEXT NOT NULL REFERENCES "checklistComponents"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL,
                "weightInGrams" REAL,
                "price" TEXT,
                "imageData" BLOB,
                "isCompleted" INTEGER NOT NULL,
                "position" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: #"CREATE INDEX "checklistItems_componentID" ON "checklistItems"("componentID")"#)
    }
}
