//
//  EventListServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The default ``EventListService`` implementation.
final class EventListServiceImplementation: EventListService {
    init() {}

    func allLists() async throws -> [List] {
        // No repository is wired up yet, so there are no lists to return.
        []
    }

    func allEvents() async throws -> [Event] {
        // No repository is wired up yet, so there are no events to return.
        []
    }
}
