//
//  EventListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A service that retrieves list models.
public protocol EventListService: Service {
    /// Retrieves all available lists.
    func allLists() async throws -> [List]

    /// Retrieves all available events.
    func allEvents() async throws -> [Event]
}


