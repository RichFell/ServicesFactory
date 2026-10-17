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
