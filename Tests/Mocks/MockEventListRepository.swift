//
//  MockEventListRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

@testable import ServicesFactory

/// An ``EventListWritableRepository`` stand-in that returns canned results or throws a canned error.
///
/// Edits are not applied; each one is recorded in ``calls`` so tests can check what was delegated.
struct MockEventListRepository: EventListWritableRepository {
    var lists: [List] = []
    var events: [Event] = []
    var error: (any Error & Sendable)?
    let calls = Calls()

    func allLists() async throws -> [List] {
        if let error { throw error }
        return lists
    }

    func allEvents() async throws -> [Event] {
        if let error { throw error }
        return events
    }

    func createList(_ list: List) async throws {
        try await record("createList(\(list.identifier))")
    }

    func updateList(_ list: List) async throws {
        try await record("updateList(\(list.identifier))")
    }

    func deleteList(identifier: String) async throws {
        try await record("deleteList(\(identifier))")
    }

    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws {
        try await record("addItem(\(item.identifier), \(listIdentifier))")
    }

    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws {
        try await record("removeItem(\(identifier), \(listIdentifier))")
    }

    func updateItem(_ item: ListItem) async throws {
        try await record("updateItem(\(item.identifier))")
    }

    func deleteItem(identifier: String) async throws {
        try await record("deleteItem(\(identifier))")
    }

    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws {
        try await record("moveItem(\(identifier), \(listIdentifier), \(position))")
    }

    private func record(_ call: String) async throws {
        if let error { throw error }
        await calls.append(call)
    }
}

extension MockEventListRepository {
    /// The edits received, in order. An actor so the mock stays `Sendable`.
    actor Calls {
        private(set) var values: [String] = []

        func append(_ call: String) {
            values.append(call)
        }
    }
}
