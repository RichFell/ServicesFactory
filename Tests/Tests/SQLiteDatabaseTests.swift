//
//  SQLiteDatabaseTests.swift
//  ServicesFactoryTests
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation
import SQLiteData
import Testing
@testable import ServicesFactory

@Table
private struct Note: Equatable, Sendable {
    let id: Int
    var title: String
}

struct SQLiteDatabaseTests {
    private static let createNotes = SQLiteDatabase.Migration(identifier: "create-notes") { db in
        try db.execute(sql: #"CREATE TABLE "notes" ("id" INTEGER PRIMARY KEY, "title" TEXT NOT NULL)"#)
    }

    private func makeDatabase() throws -> SQLiteDatabase {
        try SQLiteDatabase(location: .inMemory, migrations: [Self.createNotes])
    }

    @Test func insertThenFetchAllReturnsRecords() async throws {
        let database = try makeDatabase()
        let notes = [Note(id: 1, title: "one"), Note(id: 2, title: "two")]

        try await database.insert(notes)

        #expect(try await database.fetchAll(Note.self) == notes)
    }

    @Test func fetchOneReturnsMatchingRecordOrNil() async throws {
        let database = try makeDatabase()
        try await database.insert([Note(id: 1, title: "one")])

        #expect(try await database.fetchOne(Note.self, key: 1) == Note(id: 1, title: "one"))
        #expect(try await database.fetchOne(Note.self, key: 99) == nil)
    }

    @Test func updateOverwritesStoredRecord() async throws {
        let database = try makeDatabase()
        try await database.insert([Note(id: 1, title: "old")])

        try await database.update(Note(id: 1, title: "new"))

        #expect(try await database.fetchOne(Note.self, key: 1)?.title == "new")
    }

    @Test func deleteRemovesRecord() async throws {
        let database = try makeDatabase()
        let note = Note(id: 1, title: "gone")
        try await database.insert([note])

        try await database.delete(note)

        #expect(try await database.fetchAll(Note.self).isEmpty)
    }

    @Test func migrationsRunInOrderOnFileDatabaseAndAreNotRepeated() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("test.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let first = try SQLiteDatabase(location: .file(url), migrations: [Self.createNotes])
        try await first.insert([Note(id: 1, title: "kept")])

        // Reopening would fail on "table already exists" if the migration re-ran.
        let second = try SQLiteDatabase(location: .file(url), migrations: [Self.createNotes])

        #expect(try await second.fetchAll(Note.self) == [Note(id: 1, title: "kept")])
    }

    @Test func laterMigrationUpgradesExistingDatabaseAndKeepsData() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("test.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let addSubtitle = SQLiteDatabase.Migration(identifier: "add-notes-subtitle") { db in
            try db.execute(sql: #"ALTER TABLE "notes" ADD COLUMN "subtitle" TEXT NOT NULL DEFAULT ''"#)
        }

        let v1 = try SQLiteDatabase(location: .file(url), migrations: [Self.createNotes])
        try await v1.insert([Note(id: 1, title: "kept")])

        // Only the new migration runs; the existing row survives the schema change.
        let v2 = try SQLiteDatabase(location: .file(url), migrations: [Self.createNotes, addSubtitle])

        #expect(try await v2.fetchAll(Note.self) == [Note(id: 1, title: "kept")])
    }

    @Test func defaultMigrationsCreateFileAndChecklistTables() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("test.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let database = try SQLiteDatabase(location: .file(url))

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try await database.fetchAll(ChecklistRecord.self).isEmpty)
        #expect(try await database.fetchAll(ChecklistItemRecord.self).isEmpty)
        #expect(try await database.fetchAll(ChecklistComponentRecord.self).isEmpty)
    }

    @Test func registeredMigrationIdentifiersAreUnique() {
        let identifiers = SQLiteDatabase.Migration.all.map(\.identifier)

        #expect(Set(identifiers).count == identifiers.count)
    }
}
