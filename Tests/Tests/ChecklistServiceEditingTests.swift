//
//  ChecklistServiceEditingTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Testing
@testable import ServicesFactory

struct ChecklistServiceEditingTests {
    private struct TestError: Error, Equatable {}

    private let item = ChecklistItem(identifier: "tent", title: "Tent")

    private func makeService(_ repository: MockChecklistRepository) -> ChecklistServiceImplementation {
        ChecklistServiceImplementation(dependency: .init(localCache: repository))
    }

    @Test func editsAreDelegatedToTheRepositoryInOrder() async throws {
        let repository = MockChecklistRepository()
        let service = makeService(repository)

        try await service.createChecklist(Checklist(identifier: "pack"))
        try await service.updateChecklist(Checklist(identifier: "pack", title: "Packing"))
        try await service.addComponent(ChecklistComponent(identifier: "kitchen"), toChecklistWithIdentifier: "pack")
        try await service.updateComponent(ChecklistComponent(identifier: "kitchen", title: "Kitchen"))
        try await service.addItem(item, toComponentWithIdentifier: "kitchen")
        try await service.moveItem(identifier: "tent", inComponentWithIdentifier: "kitchen", to: 2)
        try await service.updateItem(item)
        try await service.setItem(identifier: "tent", isCompleted: true)
        try await service.deleteItem(identifier: "tent")
        try await service.deleteComponent(identifier: "kitchen")
        try await service.deleteChecklist(identifier: "pack")

        #expect(await repository.calls.values == [
            "createChecklist(pack)",
            "updateChecklist(pack)",
            "addComponent(kitchen, pack)",
            "updateComponent(kitchen)",
            "addItem(tent, kitchen)",
            "moveItem(tent, kitchen, 2)",
            "updateItem(tent)",
            "setItem(tent, true)",
            "deleteItem(tent)",
            "deleteComponent(kitchen)",
            "deleteChecklist(pack)"
        ])
    }

    @Test func copiesAreDelegatedAndReturnedFromTheRepository() async throws {
        let repository = MockChecklistRepository()
        let service = makeService(repository)

        let checklist = try await service.copyChecklist(identifier: "pack", title: "Pack 2")
        let component = try await service.copyComponent(identifier: "kitchen", toChecklistWithIdentifier: "pack2")

        #expect(checklist.title == "Pack 2")
        #expect(component.identifier == "copy")
        #expect(await repository.calls.values == ["copyChecklist(pack, Pack 2)", "copyComponent(kitchen, pack2)"])
    }

    @Test func editsPropagateRepositoryErrors() async {
        let service = makeService(MockChecklistRepository(error: TestError()))

        await #expect(throws: TestError.self) {
            try await service.createChecklist(Checklist(identifier: "pack"))
        }
        await #expect(throws: TestError.self) {
            try await service.deleteItem(identifier: "tent")
        }
        await #expect(throws: TestError.self) {
            try await service.copyChecklist(identifier: "pack", title: "Copy")
        }
    }
}
