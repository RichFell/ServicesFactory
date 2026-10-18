//
//  SQLiteDatabase+Migrations+Sections.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

extension SQLiteDatabase.Migration {
    /// Adds list sections and generic item values.
    ///
    /// Creates `listSections` with one untitled section per existing list (sharing the list's
    /// identifier) and re-points `listItemLinks` at sections instead of lists. Creates
    /// `listItemValues`, copies each item's weight into it, and rebuilds `listItems` without
    /// `weightInGrams`. Relies on GRDB disabling foreign key enforcement while a migration runs,
    /// which makes dropping the old tables safe.
    static let createListSectionsAndValues = SQLiteDatabase.Migration(identifier: "create-list-sections-and-values") { db in
        try db.execute(sql: #"ALTER TABLE "listItems" RENAME TO "listItemsOld""#)
        try db.execute(sql: #"ALTER TABLE "listItemLinks" RENAME TO "listItemLinksOld""#)
        try createItemTables(in: db)
        try createSectionTables(in: db)
        try db.execute(sql: #"DROP TABLE "listItemLinksOld""#)
        try db.execute(sql: #"DROP TABLE "listItemsOld""#)
        try db.execute(sql: #"CREATE INDEX "listItemLinks_itemID" ON "listItemLinks"("itemID")"#)
    }

    /// Rebuilds `listItems` without its weight column and moves weights into `listItemValues`.
    private static func createItemTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "listItems" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "name" TEXT NOT NULL
            )
            """)
        try db.execute(sql: #"INSERT INTO "listItems" ("id", "name") SELECT "id", "name" FROM "listItemsOld""#)
        try db.execute(sql: """
            CREATE TABLE "listItemValues" (
                "itemID" TEXT NOT NULL REFERENCES "listItems"("id") ON DELETE CASCADE,
                "field" TEXT NOT NULL,
                "value" TEXT NOT NULL,
                PRIMARY KEY ("itemID", "field")
            )
            """)
        try db.execute(sql: """
            INSERT INTO "listItemValues" ("itemID", "field", "value")
            SELECT "id", 'weight', CAST("weightInGrams" AS TEXT) FROM "listItemsOld"
            WHERE "weightInGrams" IS NOT NULL
            """)
    }

    /// Creates `listSections` and `listItemLinks` (keyed by section), moving every link into its list's section.
    private static func createSectionTables(in db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE "listSections" (
                "id" TEXT PRIMARY KEY NOT NULL,
                "listID" TEXT NOT NULL REFERENCES "lists"("id") ON DELETE CASCADE,
                "title" TEXT NOT NULL,
                "position" INTEGER NOT NULL
            )
            """)
        try db.execute(sql: #"CREATE INDEX "listSections_listID" ON "listSections"("listID")"#)
        try db.execute(sql: #"INSERT INTO "listSections" ("id", "listID", "title", "position") SELECT "id", "id", '', 0 FROM "lists""#)
        try db.execute(sql: """
            CREATE TABLE "listItemLinks" (
                "sectionID" TEXT NOT NULL REFERENCES "listSections"("id") ON DELETE CASCADE,
                "itemID" TEXT NOT NULL REFERENCES "listItems"("id") ON DELETE CASCADE,
                "position" INTEGER NOT NULL,
                PRIMARY KEY ("sectionID", "itemID")
            )
            """)
        try db.execute(sql: """
            INSERT INTO "listItemLinks" ("sectionID", "itemID", "position")
            SELECT "listID", "itemID", "position" FROM "listItemLinksOld"
            """)
    }
}
