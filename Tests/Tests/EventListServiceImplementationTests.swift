//
//  EventListServiceImplementationTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

import Testing
@testable import ServicesFactory

struct EventListServiceImplementationTests {
    @Test func allListsReturnsNoListsByDefault() async throws {
        let service = EventListServiceImplementation()
        let lists = try await service.allLists()
        #expect(lists.isEmpty)
    }

    @Test func allEventsReturnsNoEventsByDefault() async throws {
        let service = EventListServiceImplementation()
        let events = try await service.allEvents()
        #expect(events.isEmpty)
    }
}
