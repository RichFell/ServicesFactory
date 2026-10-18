//
//  EventListServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// The default ``EventListService`` implementation.
///
/// Reads and edits lists and events through the ``Dependency/localCache`` repository.
final class EventListServiceImplementation: EventListService {
    let type: ServiceType = .eventList

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func allLists() -> AsyncThrowingStream<[List], any Error> {
        dependency.localCache.allLists()
    }

    func allEvents() -> AsyncThrowingStream<[Event], any Error> {
        dependency.localCache.allEvents()
    }

    func createList(_ list: List) async throws {
        try await dependency.localCache.createList(list)
    }

    func updateList(_ list: List) async throws {
        try await dependency.localCache.updateList(list)
    }

    func deleteList(identifier: String) async throws {
        try await dependency.localCache.deleteList(identifier: identifier)
    }

    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws {
        try await dependency.localCache.addItem(item, toListWithIdentifier: listIdentifier)
    }

    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws {
        try await dependency.localCache.removeItem(identifier: identifier, fromListWithIdentifier: listIdentifier)
    }

    func updateItem(_ item: ListItem) async throws {
        try await dependency.localCache.updateItem(item)
    }

    func deleteItem(identifier: String) async throws {
        try await dependency.localCache.deleteItem(identifier: identifier)
    }

    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws {
        try await dependency.localCache.moveItem(identifier: identifier, inListWithIdentifier: listIdentifier, to: position)
    }

    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error> {
        dependency.localCache.allEventRuns()
    }

    func createEvent(_ event: Event) async throws {
        try await dependency.localCache.createEvent(event)
    }

    func updateEvent(_ event: Event) async throws {
        try await dependency.localCache.updateEvent(event)
    }

    func deleteEvent(identifier: String) async throws {
        try await dependency.localCache.deleteEvent(identifier: identifier)
    }

    func startRun(ofEventWithIdentifier eventIdentifier: String) async throws -> EventRun {
        try await dependency.localCache.startRun(
            ofEventWithIdentifier: eventIdentifier,
            identifier: UUID().uuidString,
            startedAt: Date()
        )
    }

    func setItem(
        identifier: String,
        isCompleted: Bool,
        inRunWithIdentifier runIdentifier: String
    ) async throws {
        try await dependency.localCache.setItem(
            identifier: identifier,
            isCompleted: isCompleted,
            inRunWithIdentifier: runIdentifier
        )
    }

    func setRun(identifier: String, isComplete: Bool) async throws {
        try await dependency.localCache.setRun(
            identifier: identifier,
            isComplete: isComplete,
            at: Date()
        )
    }

    func deleteRun(identifier: String) async throws {
        try await dependency.localCache.deleteRun(identifier: identifier)
    }
}

extension EventListServiceImplementation {
    /// The collaborators an ``EventListServiceImplementation`` needs.
    struct Dependency: Sendable {
        /// The repository holding locally cached lists and events, and applying edits to them.
        let localCache: EventListWritableRepository

        init(localCache: EventListWritableRepository) {
            self.localCache = localCache
        }

        /// A dependency backed by a ``SQLiteDatabase`` at `databaseLocation`.
        static func live(databaseLocation: SQLiteDatabase.Location) throws -> Dependency {
            let database = try SQLiteDatabase(location: databaseLocation)
            return Dependency(localCache: EventListLocalCacheRepository(database: database))
        }
    }
}
