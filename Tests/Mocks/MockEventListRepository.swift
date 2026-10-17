//
//  MockEventListRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

@testable import ServicesFactory

/// An ``EventListRepository`` stand-in that returns canned results or throws a canned error.
struct MockEventListRepository: EventListRepository {
    var lists: [List] = []
    var events: [Event] = []
    var error: (any Error & Sendable)?

    func allLists() async throws -> [List] {
        if let error { throw error }
        return lists
    }

    func allEvents() async throws -> [Event] {
        if let error { throw error }
        return events
    }
}
