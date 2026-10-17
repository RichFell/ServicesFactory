//
//  EventListServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The default ``EventListService`` implementation.
///
/// Reads lists and events from the ``Dependency/localCache`` repository.
final class EventListServiceImplementation: EventListService {
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
}

extension EventListServiceImplementation {
    /// The collaborators an ``EventListServiceImplementation`` needs.
    struct Dependency: Sendable {
        /// The repository holding locally cached lists and events.
        let localCache: EventListRepository

        init(localCache: EventListRepository) {
            self.localCache = localCache
        }

        /// A dependency backed by a ``SQLiteDatabase`` at `databaseLocation`.
        static func live(databaseLocation: SQLiteDatabase.Location) throws -> Dependency {
            let database = try SQLiteDatabase(location: databaseLocation)
            return Dependency(localCache: EventListLocalCacheRepository(database: database))
        }
    }
}
