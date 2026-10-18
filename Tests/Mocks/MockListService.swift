//
//  MockListService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

@testable import ServicesFactory

/// A ``EventListService`` stand-in used to register custom services with a factory.
final class MockListService: EventListService {
    let type: ServiceType = .eventList

    func allLists() -> AsyncThrowingStream<[List], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func allEvents() -> AsyncThrowingStream<[Event], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func createList(_ list: List) async throws {}

    func updateList(_ list: List) async throws {}

    func deleteList(identifier: String) async throws {}

    func addSection(_ section: ListSection, toListWithIdentifier listIdentifier: String) async throws {}

    func updateSection(_ section: ListSection) async throws {}

    func deleteSection(identifier: String) async throws {}

    func addItem(_ item: ListItem, toSectionWithIdentifier sectionIdentifier: String) async throws {}

    func removeItem(identifier: String, fromSectionWithIdentifier sectionIdentifier: String) async throws {}

    func updateItem(_ item: ListItem) async throws {}

    func deleteItem(identifier: String) async throws {}

    func moveItem(identifier: String, inSectionWithIdentifier sectionIdentifier: String, to position: Int) async throws {}

    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func createEvent(_ event: Event) async throws {}

    func updateEvent(_ event: Event) async throws {}

    func deleteEvent(identifier: String) async throws {}

    func startRun(ofEventWithIdentifier eventIdentifier: String) async throws -> EventRun {
        EventRun(identifier: "", eventIdentifier: eventIdentifier, title: "")
    }

    func setItem(
        identifier: String,
        isCompleted: Bool,
        inListWithIdentifier listIdentifier: String,
        inRunWithIdentifier runIdentifier: String
    ) async throws {}

    func setRun(identifier: String, isComplete: Bool) async throws {}

    func deleteRun(identifier: String) async throws {}
}
