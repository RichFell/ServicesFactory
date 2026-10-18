//
//  MockChecklistService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

@testable import ServicesFactory

/// A ``ChecklistService`` stand-in used to register custom services with a factory.
final class MockChecklistService: ChecklistService {
    let type: ServiceType = .checklist

    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func createChecklist(_ checklist: Checklist) async throws {}

    func updateChecklist(_ checklist: Checklist) async throws {}

    func deleteChecklist(identifier: String) async throws {}

    func copyChecklist(identifier: String, title: String) async throws -> Checklist {
        Checklist(identifier: "copy", title: title)
    }

    func addComponent(_ component: ChecklistComponent, toChecklistWithIdentifier checklistIdentifier: String) async throws {}

    func updateComponent(_ component: ChecklistComponent) async throws {}

    func deleteComponent(identifier: String) async throws {}

    func copyComponent(identifier: String, toChecklistWithIdentifier checklistIdentifier: String) async throws -> ChecklistComponent {
        ChecklistComponent(identifier: "copy")
    }

    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws {}

    func updateItem(_ item: ChecklistItem) async throws {}

    func setItem(identifier: String, isCompleted: Bool) async throws {}

    func deleteItem(identifier: String) async throws {}

    func moveItem(identifier: String, inComponentWithIdentifier componentIdentifier: String, to position: Int) async throws {}
}
