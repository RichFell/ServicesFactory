//
//  EventListServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The default ``EventListService`` implementation.
///
/// Reads and edits lists and events through the ``Dependency/localCache`` repository.
final class EventListServiceImplementation: EventListService {
    let type: ServiceType = .eventList

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func allLists() async throws -> [List] {
        try await dependency.localCache.allLists()
    }

    func allEvents() async throws -> [Event] {
        try await dependency.localCache.allEvents()
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
