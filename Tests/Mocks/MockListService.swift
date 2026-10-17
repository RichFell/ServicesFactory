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

    func createList(_ list: List) async throws {}

    func updateList(_ list: List) async throws {}

    func deleteList(identifier: String) async throws {}

    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws {}

    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws {}

    func updateItem(_ item: ListItem) async throws {}

    func deleteItem(identifier: String) async throws {}

    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws {}
}
