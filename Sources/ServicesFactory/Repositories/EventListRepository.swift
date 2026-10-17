//
//  EventListRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A repository that retrieves list models from a data source.
protocol EventListRepository: Sendable {
    /// Retrieves all available lists.
    func allLists() async throws -> [List]

    /// Retrieves all available events, with their lists and completed items resolved.
    func allEvents() async throws -> [Event]
}
