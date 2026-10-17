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

    func allLists() async throws -> [List] {
        let data = try await fetchData()
        return try builder.decode(data)
    }

    func allEvents() async throws -> [Event] {
        // The raw data source only provides lists, so there are no events to return.
        []
    }
}
