//
//  MockListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

@testable import ServicesFactory

/// A ``EventListService`` stand-in used to register custom services with a factory.
final class MockListService: EventListService {
    func allLists() async throws -> [List] {
        []
    }

    func allEvents() async throws -> [Event] {
        []
    }
}
