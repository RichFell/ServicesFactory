//
//  SQLiteDatabase+Migrations+RunSnapshots.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import class GRDB.Row
import SQLiteData

extension SQLiteDatabase.Migration {
    /// Stores each run's lists as one JSON snapshot and tracks completion per list.
    ///
    /// Rebuilds `eventRuns` with a `snapshot` column and no foreign key to `events`, so a run
    /// outlives its event. Each run's rows in `eventRunLists`, `eventRunListFields` and
    /// `eventRunItems` are encoded into that snapshot (one section per list) and the tables are
    /// dropped. `eventRunCompletedItems` gains a `listID`; an item completed before is marked
    /// completed in every list of the run that contained it.
    static let snapshotEventRuns = SQLiteDatabase.Migration(identifier: "snapshot-event-runs") { db in
        try db.execute(sql: #"ALTER TABLE "eventRuns" RENAME TO "eventRunsOld""#)
        try db.execute(sql: #"ALTER TABLE "eventRunCompletedItems" RENAME TO "eventRunCompletedItemsOld""#)
        try createSnapshotTables(in: db)
        try copyRuns(in: db)
        try db.execute(sql: """
            INSERT INTO "eventRunCompletedItems" ("runID", "listID", "itemID")
            SELECT c."runID", i."listID", c."itemID"
            FROM "eventRunCompletedItemsOld" c
            JOIN "eventRunItems" i ON i."runID" = c."runID" AND i."itemID" = c."itemID"
            """)
        for table in ["eventRunCompletedItemsOld", "eventRunItems", "eventRunListFields", "eventRunLists", "eventRunsOld"] {
            try db.execute(sql: "DROP TABLE \"\(table)\"")
        }
    }

    private static func createSnapshotTables(in db: Database) throws {
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

    /// Copies every old run row, adding its encoded snapshot.
    private static func copyRuns(in db: Database) throws {
        for row in try Row.fetchAll(db, sql: #"SELECT * FROM "eventRunsOld""#) {
            let id: String = row["id"]
            let snapshot = try legacySnapshotJSON(forRun: id, in: db)
            try db.execute(
                sql: """
                    INSERT INTO "eventRuns" ("id", "eventID", "title", "isComplete", "startedAt", "completedAt", "snapshot")
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [
                    id,
                    row["eventID"] as String,
                    row["title"] as String,
                    row["isComplete"] as Int,
                    row["startedAt"] as Double,
                    row["completedAt"] as Double?,
                    snapshot
                ]
            )
        }
    }

    /// Builds the snapshot JSON for a run from its legacy list, field and item rows.
    private static func legacySnapshotJSON(forRun runID: String, in db: Database) throws -> String {
        var lists: [LegacyList] = []
        let listRows = try Row.fetchAll(
            db,
            sql: #"SELECT "listID", "title" FROM "eventRunLists" WHERE "runID" = ? ORDER BY "position""#,
            arguments: [runID]
        )
        for listRow in listRows {
            let listID: String = listRow["listID"]
            let fields = try String.fetchAll(
                db,
                sql: #"SELECT "field" FROM "eventRunListFields" WHERE "runID" = ? AND "listID" = ? ORDER BY "field""#,
                arguments: [runID, listID]
            )
            let itemRows = try Row.fetchAll(
                db,
                sql: #"SELECT "itemID", "name", "weightInGrams" FROM "eventRunItems" WHERE "runID" = ? AND "listID" = ? ORDER BY "position""#,
                arguments: [runID, listID]
            )
            let items = itemRows.map { row -> LegacyItem in
                let grams: Double? = row["weightInGrams"]
                return LegacyItem(
                    identifier: row["itemID"],
                    name: row["name"],
                    values: grams.map { ["weight": "\($0)"] } ?? [:]
                )
            }
            let section = LegacySection(identifier: listID, title: "", items: items)
            lists.append(LegacyList(identifier: listID, title: listRow["title"], fields: fields, sections: [section]))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(LegacySnapshot(lists: lists)), as: UTF8.self)
    }

    // The snapshot format as of this migration, frozen so later changes to ``EventRunSnapshot`` can't alter it.

    private struct LegacySnapshot: Encodable {
        let lists: [LegacyList]
    }

    private struct LegacyList: Encodable {
        let identifier: String
        let title: String
        let fields: [String]
        let sections: [LegacySection]
    }

    private struct LegacySection: Encodable {
        let identifier: String
        let title: String
        let items: [LegacyItem]
    }

    private struct LegacyItem: Encodable {
        let identifier: String
        let name: String
        let values: [String: String]
    }
}
