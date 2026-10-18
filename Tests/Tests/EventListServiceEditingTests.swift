//
//  EventListServiceEditingTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Testing
@testable import ServicesFactory

struct EventListServiceEditingTests {
    private struct TestError: Error, Equatable {}

    private let item = ListItem(identifier: "tent", name: "Tent")

    private func makeService(_ repository: MockEventListRepository) -> EventListServiceImplementation {
        EventListServiceImplementation(dependency: .init(localCache: repository))
    }

    @Test func editsAreDelegatedToTheRepositoryInOrder() async throws {
        let repository = MockEventListRepository()
        let service = makeService(repository)

        try await service.createList(List(identifier: "pack"))
        try await service.updateList(List(identifier: "pack", title: "Packing"))
        try await service.addItem(item, toListWithIdentifier: "pack")
        try await service.moveItem(identifier: "tent", inListWithIdentifier: "pack", to: 2)
        try await service.updateItem(item)
        try await service.removeItem(identifier: "tent", fromListWithIdentifier: "pack")
        try await service.deleteItem(identifier: "tent")
        try await service.deleteList(identifier: "pack")

        #expect(await repository.calls.values == [
            "createList(pack)",
            "updateList(pack)",
            "addItem(tent, pack)",
            "moveItem(tent, pack, 2)",
            "updateItem(tent)",
            "removeItem(tent, pack)",
            "deleteItem(tent)",
            "deleteList(pack)"
        ])
    }

    @Test func eventAndRunEditsAreDelegatedToTheRepositoryInOrder() async throws {
        let repository = MockEventListRepository()
        let service = makeService(repository)

        try await service.createEvent(Event(identifier: "trip", title: "Trip"))
        try await service.updateEvent(Event(identifier: "trip", title: "Trip 2"))
        let run = try await service.startRun(ofEventWithIdentifier: "trip")
        try await service.setItem(identifier: "tent", isCompleted: true, inRunWithIdentifier: run.identifier)
        try await service.setRun(identifier: run.identifier, isComplete: true)
        try await service.deleteRun(identifier: run.identifier)
        try await service.deleteEvent(identifier: "trip")

        #expect(run.eventIdentifier == "trip")
        #expect(!run.identifier.isEmpty)
        #expect(await repository.calls.values == [
            "createEvent(trip)",
            "updateEvent(trip)",
            "startRun(trip, \(run.identifier))",
            "setItem(tent, true, \(run.identifier))",
            "setRun(\(run.identifier), true)",
            "deleteRun(\(run.identifier))",
            "deleteEvent(trip)"
        ])
    }

    @Test func allEventRunsStreamsTheRepositoryRuns() async throws {
        var repository = MockEventListRepository()
        repository.runs = [EventRun(identifier: "run", eventIdentifier: "trip", title: "Trip")]

        let runs = try await makeService(repository).allEventRuns().firstValue()

        #expect(runs.map(\.identifier) == ["run"])
    }

    @Test func editsPropagateRepositoryErrors() async {
        let service = makeService(MockEventListRepository(error: TestError()))

        await #expect(throws: TestError.self) {
            try await service.createList(List(identifier: "pack"))
        }
        await #expect(throws: TestError.self) {
            try await service.deleteItem(identifier: "tent")
        }
    }
}
