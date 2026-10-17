//
//  EventListLocalCacheRepositoryEditingTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListLocalCacheRepositoryEditingTests {
    private let database: SQLiteDatabase
    private let repository: EventListLocalCacheRepository

    init() throws {
        database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = EventListLocalCacheRepository(database: database)
    }

    private let tent = ListItem(identifier: "tent", name: "Tent", weight: Measurement(value: 1500, unit: .grams))
    private let stove = ListItem(identifier: "stove", name: "Stove")

    private func list(_ identifier: String, items: [ListItem] = []) -> List {
        List(identifier: identifier, title: identifier.capitalized, items: items)
    }

    private func itemIdentifiers(of listIdentifier: String) async throws -> [String]? {
        try await repository.allLists().first { $0.identifier == listIdentifier }?.items.map(\.identifier)
    }

    // MARK: - Lists

    @Test func createListStoresFieldsAndOrderedItems() async throws {
        let created = List(identifier: "pack", title: "Packing", fields: [.weight], items: [tent, stove])

        try await repository.createList(created)
        let stored = try #require(try await repository.allLists().first)

        #expect(stored.title == "Packing")
        #expect(stored.fields == [.weight])
        #expect(stored.items.map(\.identifier) == ["tent", "stove"])
        #expect(stored.items[0].weight == Measurement(value: 1500, unit: .grams))
    }

    @Test func createListLinksExistingItemsInsteadOfDuplicatingThem() async throws {
        try await repository.createList(list("one", items: [tent]))
        try await repository.createList(list("two", items: [tent]))

        #expect(try await database.fetchAll(ListItemRecord.self).count == 1)
        #expect(try await itemIdentifiers(of: "two") == ["tent"])
    }

    @Test func updateListChangesTitleAndFieldsButNotItems() async throws {
        try await repository.createList(list("pack", items: [tent]))

        try await repository.updateList(List(identifier: "pack", title: "Renamed", fields: [.weight], items: []))
        let stored = try #require(try await repository.allLists().first)

        #expect(stored.title == "Renamed")
        #expect(stored.fields == [.weight])
        #expect(stored.items.map(\.identifier) == ["tent"])
    }

    @Test func updateListThrowsWhenListIsMissing() async {
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.updateList(list("nope"))
        }
    }

    @Test func deleteListKeepsItsItemsAndOtherLists() async throws {
        try await repository.createList(list("one", items: [tent, stove]))
        try await repository.createList(list("two", items: [tent]))

        try await repository.deleteList(identifier: "one")

        #expect(try await itemIdentifiers(of: "one") == nil)
        #expect(try await itemIdentifiers(of: "two") == ["tent"])
        #expect(Set(try await database.fetchAll(ListItemRecord.self).map(\.id)) == ["tent", "stove"])
        #expect(try await database.fetchAll(ListItemLinkRecord.self).map(\.listID) == ["two"])
    }

    @Test func storeKeepsItemsSharedWithOtherLists() async throws {
        try await repository.createList(list("one", items: [tent]))

        try await repository.store([list("two", items: [tent])])

        #expect(try await itemIdentifiers(of: "one") == ["tent"])
        #expect(try await itemIdentifiers(of: "two") == ["tent"])
    }

    // MARK: - Items

    @Test func addItemAppendsToTheEndAndIsIdempotent() async throws {
        try await repository.createList(list("pack", items: [tent]))

        try await repository.addItem(stove, toListWithIdentifier: "pack")
        try await repository.addItem(stove, toListWithIdentifier: "pack")

        #expect(try await itemIdentifiers(of: "pack") == ["tent", "stove"])
    }

    @Test func addItemSharesOneItemBetweenLists() async throws {
        try await repository.createList(list("one"))
        try await repository.createList(list("two"))

        try await repository.addItem(tent, toListWithIdentifier: "one")
        try await repository.addItem(tent, toListWithIdentifier: "two")

        #expect(try await itemIdentifiers(of: "one") == ["tent"])
        #expect(try await itemIdentifiers(of: "two") == ["tent"])
        #expect(try await database.fetchAll(ListItemRecord.self).count == 1)
    }

    @Test func addItemThrowsWhenListIsMissing() async throws {
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.addItem(tent, toListWithIdentifier: "nope")
        }
        #expect(try await database.fetchAll(ListItemRecord.self).isEmpty)
    }

    @Test func removeItemUnlinksOnlyFromThatList() async throws {
        try await repository.createList(list("one", items: [tent]))
        try await repository.createList(list("two", items: [tent]))

        try await repository.removeItem(identifier: "tent", fromListWithIdentifier: "one")

        #expect(try await itemIdentifiers(of: "one") == [])
        #expect(try await itemIdentifiers(of: "two") == ["tent"])
        #expect(try await database.fetchAll(ListItemRecord.self).count == 1)
    }

    @Test func updateItemChangesItInEveryList() async throws {
        try await repository.createList(list("one", items: [tent]))
        try await repository.createList(list("two", items: [tent]))

        try await repository.updateItem(ListItem(identifier: "tent", name: "Big tent"))
        let lists = try await repository.allLists()

        #expect(lists.flatMap(\.items).map(\.name) == ["Big tent", "Big tent"])
        #expect(lists.flatMap(\.items).allSatisfy { $0.weight == nil })
    }

    @Test func updateItemThrowsWhenItemIsMissing() async {
        await #expect(throws: EventListError.itemNotFound(identifier: "tent")) {
            try await repository.updateItem(tent)
        }
    }

    @Test func deleteItemRemovesItFromEveryListAndEvent() async throws {
        try await repository.createList(list("one", items: [tent, stove]))
        try await repository.createList(list("two", items: [tent]))
        let event = Event(identifier: "trip", title: "Trip", completedItemIdentifiers: ["tent", "stove"])
        try await database.insert([EventRecord(event)])
        try await database.insert(EventCompletedItemRecord.records(for: event))

        try await repository.deleteItem(identifier: "tent")

        #expect(try await itemIdentifiers(of: "one") == ["stove"])
        #expect(try await itemIdentifiers(of: "two") == [])
        #expect(try await repository.allEvents().first?.completedItemIdentifiers == ["stove"])
    }

    @Test func moveItemReordersWithinTheList() async throws {
        let map = ListItem(identifier: "map", name: "Map")
        try await repository.createList(list("pack", items: [tent, stove, map]))

        try await repository.moveItem(identifier: "map", inListWithIdentifier: "pack", to: 0)

        #expect(try await itemIdentifiers(of: "pack") == ["map", "tent", "stove"])
    }

    @Test func moveItemThrowsWhenListOrItemIsMissing() async throws {
        try await repository.createList(list("pack", items: [tent]))

        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.moveItem(identifier: "tent", inListWithIdentifier: "nope", to: 0)
        }
        await #expect(throws: EventListError.itemNotFound(identifier: "stove")) {
            try await repository.moveItem(identifier: "stove", inListWithIdentifier: "pack", to: 0)
        }
    }
}
