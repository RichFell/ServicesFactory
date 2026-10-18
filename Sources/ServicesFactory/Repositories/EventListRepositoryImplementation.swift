//
//  EventListRepositoryImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// The default ``EventListRepository`` implementation.
///
/// Retrieves raw list data from an injected data source and uses its
/// ``EventListBuilder`` to decode that data into ``List`` models.
final class EventListRepositoryImplementation: EventListRepository {
    private let builder: EventListBuilder
    private let fetchData: @Sendable () async throws -> Data

    init(
        builder: EventListBuilder = EventListBuilder(),
        fetchData: @escaping @Sendable () async throws -> Data
    ) {
        self.builder = builder
        self.fetchData = fetchData
    }

    /// Yields the decoded lists once, then finishes. The raw data source does not report changes.
    func allLists() -> AsyncThrowingStream<[List], any Error> {
        let builder = builder
        let fetchData = fetchData
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try builder.decode(try await fetchData()))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func allEvents() -> AsyncThrowingStream<[Event], any Error> {
        // The raw data source only provides lists, so there are no events to return.
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }
}
