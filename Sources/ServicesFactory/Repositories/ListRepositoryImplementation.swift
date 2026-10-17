//
//  ListRepositoryImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Foundation

/// The default ``ListRepository`` implementation.
///
/// Retrieves raw list data from an injected data source and uses its
/// ``ListBuilder`` to decode that data into ``List`` models.
final class ListRepositoryImplementation: ListRepository {
    private let builder: ListBuilder
    private let fetchData: @Sendable () async throws -> Data

    init(
        builder: ListBuilder = ListBuilder(),
        fetchData: @escaping @Sendable () async throws -> Data
    ) {
        self.builder = builder
        self.fetchData = fetchData
    }

    func allLists() async throws -> [List] {
        let data = try await fetchData()
        return try builder.decode(data)
    }
}
