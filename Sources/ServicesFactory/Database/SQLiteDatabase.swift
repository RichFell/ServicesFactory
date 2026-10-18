//
//  SQLiteDatabase.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import Foundation
import struct GRDB.ValueObservation
import OSLog
import SQLiteData

/// Encapsulates a SQLite database and its CRUD operations.
///
/// On creation it resolves the database file inside the app container, opens the
/// connection (a `DatabasePool` for files, a `DatabaseQueue` for in-memory) and
/// runs any pending migrations before the instance is handed back.
final class SQLiteDatabase: Sendable {
    private static let logger = Logger(subsystem: "ServicesFactory", category: "SQLiteDatabase")

    private let writer: any DatabaseWriter

    /// Opens the database at `location` and applies `migrations` in order.
    ///
    /// - Parameters:
    ///   - location: Where the database lives. Defaults to a file in Application Support.
    ///   - migrations: Ordered schema migrations. Already applied identifiers are skipped.
    ///     Defaults to ``Migration/all`` so a new database always gets the full schema and an
    ///     existing one is upgraded to it.
    init(
        location: Location = .applicationSupport(fileName: "ServicesFactory.sqlite"),
        migrations: [Migration] = Migration.all
    ) throws {
        let writer = try Self.makeWriter(location: location)
        try Self.migrate(writer, with: migrations)
        self.writer = writer
    }

    // MARK: - Create

    /// Inserts `records` into their table.
    func insert<T: Table & Sendable>(_ records: [T]) async throws {
        try await writer.write { db in
            try T.insert { records }.execute(db)
        }
        Self.logger.debug("Inserted \(records.count) \(String(describing: T.self)) record(s)")
    }

    // MARK: - Read

    /// Returns every row in the table for `type`.
    func fetchAll<T: Table & Sendable>(_ type: T.Type) async throws -> [T] where T.QueryOutput == T {
        try await writer.read { db in
            try T.fetchAll(db)
        }
    }

    /// Returns the row with the given primary key, or `nil` when none exists.
    func fetchOne<T: PrimaryKeyedTable & Sendable>(
        _ type: T.Type,
        key: T.PrimaryKey
    ) async throws -> T? where T.QueryOutput == T, T.PrimaryKey: Sendable {
        try await writer.read { db in
            try T.find(key).fetchOne(db)
        }
    }

    /// Streams the result of `fetch`, first with the current database contents and then again
    /// after every committed change to the tables `fetch` reads.
    ///
    /// Each call starts its own observation, so a new subscriber immediately receives the
    /// latest value. The stream ends with the error if `fetch` throws, and cancelling the
    /// consumer stops the observation.
    func observe<Value: Sendable>(
        _ fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AsyncThrowingStream<Value, any Error> {
        let observation = ValueObservation.tracking(fetch)
        let writer = writer
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in observation.values(in: writer) {
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    Self.logger.error("Observation failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Update

    /// Overwrites the stored row whose primary key matches `record`.
    func update<T: PrimaryKeyedTable & Sendable>(_ record: T) async throws {
        try await writer.write { db in
            try T.update(record).execute(db)
        }
        Self.logger.debug("Updated \(String(describing: T.self)) record")
    }

    // MARK: - Delete

    /// Deletes the stored row matching `record`.
    func delete<T: PrimaryKeyedTable & Sendable>(_ record: T) async throws {
        try await writer.write { db in
            try T.delete(record).execute(db)
        }
        Self.logger.debug("Deleted \(String(describing: T.self)) record")
    }

    /// Deletes every row of `type` matching `isIncluded`.
    func delete<T: Table & Sendable>(
        _ type: T.Type,
        where isIncluded: @escaping @Sendable (T.TableColumns) -> some QueryExpression<Bool>
    ) async throws {
        // Built outside the closure so the opaque predicate type isn't captured.
        // The statement is an immutable value used once, so crossing into the writer is safe.
        nonisolated(unsafe) let statement = T.where(isIncluded).delete()
        try await writer.write { db in
            try statement.execute(db)
        }
        Self.logger.debug("Deleted matching \(String(describing: T.self)) record(s)")
    }

    // MARK: - Transactions

    /// Runs `updates` in a single transaction: every change is applied, or none if it throws.
    func transaction(_ updates: @escaping @Sendable (Database) throws -> Void) async throws {
        try await writer.write(updates)
    }

    // MARK: - Setup

    private static func makeWriter(location: Location) throws -> any DatabaseWriter {
        guard let url = try location.fileURL() else {
            logger.info("Opening in-memory database")
            return try DatabaseQueue()
        }
        logger.info("Opening database at \(url.path)")
        return try DatabasePool(path: url.path)
    }

    private static func migrate(
        _ writer: any DatabaseWriter,
        with migrations: [Migration]
    ) throws {
        var migrator = DatabaseMigrator()
        for migration in migrations {
            migrator.registerMigration(migration.identifier, migrate: migration.run)
        }
        try migrator.migrate(writer)
        logger.info("Migrations complete (\(migrations.count) registered)")
    }
}

// MARK: - Nested Types

extension SQLiteDatabase {
    /// A named, one-time schema change.
    struct Migration: Sendable {
        /// Unique, stable identifier recorded once the migration has run.
        let identifier: String

        /// Applies the schema change.
        let run: @Sendable (Database) throws -> Void
    }

    /// Where the database is stored.
    enum Location: Sendable {
        case inMemory
        case applicationSupport(fileName: String)
        case file(URL)

        /// Resolves the on-disk URL, creating its parent directory. `nil` for in-memory.
        func fileURL() throws -> URL? {
            let url: URL
            switch self {
            case .inMemory:
                return nil
            case .file(let fileURL):
                url = fileURL
            case .applicationSupport(let fileName):
                url = try FileManager.default
                    .url(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                    )
                    .appendingPathComponent(fileName)
            }
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            return url
        }
    }
}
