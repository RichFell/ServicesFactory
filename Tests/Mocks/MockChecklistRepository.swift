//
//  MockChecklistRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

@testable import ServicesFactory

/// A ``ChecklistWritableRepository`` stand-in that returns canned results or throws a canned error.
///
/// Edits are not applied; each one is recorded in ``calls`` so tests can check what was delegated.
struct MockChecklistRepository: ChecklistWritableRepository {
    var checklists: [Checklist] = []
    var error: (any Error & Sendable)?
    let calls = Calls()

    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error> {
        let error = error
        let checklists = checklists
        return AsyncThrowingStream { continuation in
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(checklists)
                continuation.finish()
            }
        }
    }

    func createChecklist(_ checklist: Checklist) async throws {
        try await record("createChecklist(\(checklist.identifier))")
    }

    func updateChecklist(_ checklist: Checklist) async throws {
        try await record("updateChecklist(\(checklist.identifier))")
    }

    func deleteChecklist(identifier: String) async throws {
        try await record("deleteChecklist(\(identifier))")
    }

    func copyChecklist(identifier: String, title: String) async throws -> Checklist {
        try await record("copyChecklist(\(identifier), \(title))")
        return Checklist(identifier: "copy", title: title)
    }

    func addComponent(_ component: ChecklistComponent, toChecklistWithIdentifier checklistIdentifier: String) async throws {
        try await record("addComponent(\(component.identifier), \(checklistIdentifier))")
    }

    func updateComponent(_ component: ChecklistComponent) async throws {
        try await record("updateComponent(\(component.identifier))")
    }

    func deleteComponent(identifier: String) async throws {
        try await record("deleteComponent(\(identifier))")
    }

    func copyComponent(identifier: String, toChecklistWithIdentifier checklistIdentifier: String) async throws -> ChecklistComponent {
        try await record("copyComponent(\(identifier), \(checklistIdentifier))")
        return ChecklistComponent(identifier: "copy")
    }

    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws {
        try await record("addItem(\(item.identifier), \(componentIdentifier))")
    }

    func updateItem(_ item: ChecklistItem) async throws {
        try await record("updateItem(\(item.identifier))")
    }

    func setItem(identifier: String, isCompleted: Bool) async throws {
        try await record("setItem(\(identifier), \(isCompleted))")
    }

    func deleteItem(identifier: String) async throws {
        try await record("deleteItem(\(identifier))")
    }

    func moveItem(identifier: String, inComponentWithIdentifier componentIdentifier: String, to position: Int) async throws {
        try await record("moveItem(\(identifier), \(componentIdentifier), \(position))")
    }

    private func record(_ call: String) async throws {
        if let error { throw error }
        await calls.append(call)
    }
}

extension MockChecklistRepository {
    /// The edits received, in order. An actor so the mock stays `Sendable`.
    actor Calls {
        private(set) var values: [String] = []

        func append(_ call: String) {
            values.append(call)
        }
    }
}
