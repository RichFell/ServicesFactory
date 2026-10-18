//
//  ChecklistLocalCacheRepositoryEditingTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistLocalCacheRepositoryEditingTests {
    private let database: SQLiteDatabase
    private let repository: ChecklistLocalCacheRepository

    init() throws {
        database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = ChecklistLocalCacheRepository(database: database)
    }

    private let tent = ChecklistItem(identifier: "tent", title: "Tent", weight: Measurement(value: 1500, unit: .grams))
    private let stove = ChecklistItem(identifier: "stove", title: "Stove")

    private func checklist(_ identifier: String, items: [ChecklistItem] = []) -> Checklist {
        Checklist(identifier: identifier, title: identifier.capitalized, items: items)
    }

    private func itemIdentifiers(of identifier: String) async throws -> [String]? {
        try await repository.allChecklists().firstValue().first { $0.identifier == identifier }?.items.map(\.identifier)
    }

    // MARK: - Checklists

    @Test func createChecklistStoresTypeFlatSettingAndOrderedItems() async throws {
        let created = Checklist(identifier: "pack", title: "Packing", type: .weight, items: [tent, stove])

        try await repository.createChecklist(created)
        let stored = try #require(try await repository.allChecklists().firstValue().first)

        #expect(stored.title == "Packing")
        #expect(stored.type == .weight)
        #expect(stored.isFlatList)
        #expect(stored.items.map(\.identifier) == ["tent", "stove"])
    }

    @Test func createChecklistRejectsAFlatChecklistWithoutExactlyOneComponent() async {
        let invalid = Checklist(identifier: "x", isFlatList: true, components: [])

        await #expect(throws: ChecklistError.flatChecklistRequiresOneComponent(identifier: "x")) {
            try await repository.createChecklist(invalid)
        }
    }

    @Test func updateChecklistChangesTitleAndTypeButNotComponents() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent]))

        try await repository.updateChecklist(Checklist(identifier: "pack", title: "Renamed", type: .price, items: []))
        let stored = try #require(try await repository.allChecklists().firstValue().first)

        #expect(stored.title == "Renamed")
        #expect(stored.type == .price)
        #expect(stored.items.map(\.identifier) == ["tent"])
    }

    @Test func updateChecklistThrowsWhenMissingOrWhenFlatWithManyComponents() async throws {
        await #expect(throws: ChecklistError.checklistNotFound(identifier: "nope")) {
            try await repository.updateChecklist(checklist("nope"))
        }

        let multi = Checklist(
            identifier: "multi",
            components: [ChecklistComponent(identifier: "a"), ChecklistComponent(identifier: "b")]
        )
        try await repository.createChecklist(multi)
        await #expect(throws: ChecklistError.flatChecklistRequiresOneComponent(identifier: "multi")) {
            try await repository.updateChecklist(Checklist(identifier: "multi", items: []))
        }
    }

    @Test func deleteChecklistRemovesItsComponentsAndItemsOnly() async throws {
        try await repository.createChecklist(checklist("one", items: [tent, stove]))
        try await repository.createChecklist(checklist("two", items: [ChecklistItem(identifier: "map", title: "Map")]))

        try await repository.deleteChecklist(identifier: "one")

        #expect(try await itemIdentifiers(of: "one") == nil)
        #expect(try await itemIdentifiers(of: "two") == ["map"])
        #expect(try await database.fetchAll(ChecklistItemRecord.self).map(\.id) == ["map"])
        #expect(try await database.fetchAll(ChecklistComponentRecord.self).count == 1)
    }

    // MARK: - Items

    @Test func addItemAppendsToTheEndOfTheComponent() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent]))

        try await repository.addItem(stove, toComponentWithIdentifier: "pack")

        #expect(try await itemIdentifiers(of: "pack") == ["tent", "stove"])
    }

    @Test func addItemThrowsWhenComponentIsMissing() async throws {
        await #expect(throws: ChecklistError.componentNotFound(identifier: "nope")) {
            try await repository.addItem(tent, toComponentWithIdentifier: "nope")
        }
        #expect(try await database.fetchAll(ChecklistItemRecord.self).isEmpty)
    }

    @Test func updateItemChangesEveryDetailAndKeepsItsPlace() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent, stove]))
        let updated = ChecklistItem(
            identifier: "tent",
            title: "Big tent",
            weight: nil,
            price: Decimal(string: "250.25"),
            imageData: Data([9]),
            isCompleted: true
        )

        try await repository.updateItem(updated)
        let items = try #require(try await repository.allChecklists().firstValue().first?.items)

        #expect(items.map(\.identifier) == ["tent", "stove"])
        #expect(items[0].title == "Big tent")
        #expect(items[0].weight == nil)
        #expect(items[0].price == Decimal(string: "250.25"))
        #expect(items[0].imageData == Data([9]))
        #expect(items[0].isCompleted)
    }

    @Test func updateAndSetItemThrowWhenItemIsMissing() async {
        await #expect(throws: ChecklistError.itemNotFound(identifier: "tent")) {
            try await repository.updateItem(tent)
        }
        await #expect(throws: ChecklistError.itemNotFound(identifier: "tent")) {
            try await repository.setItem(identifier: "tent", isCompleted: true)
        }
    }

    @Test func setItemMarksOnlyThatItemCompleted() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent, stove]))

        try await repository.setItem(identifier: "stove", isCompleted: true)
        let items = try #require(try await repository.allChecklists().firstValue().first?.items)

        #expect(items.map(\.isCompleted) == [false, true])

        try await repository.setItem(identifier: "stove", isCompleted: false)
        #expect(try await repository.allChecklists().firstValue().first?.items.map(\.isCompleted) == [false, false])
    }

    @Test func checklistIsCompleteOnceEveryItemIsCompleted() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent, stove]))
        try await repository.setItem(identifier: "tent", isCompleted: true)
        #expect(try await repository.allChecklists().firstValue().first?.isComplete == false)

        try await repository.setItem(identifier: "stove", isCompleted: true)

        #expect(try await repository.allChecklists().firstValue().first?.isComplete == true)
    }

    @Test func deleteItemRemovesOnlyThatItem() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent, stove]))

        try await repository.deleteItem(identifier: "tent")

        #expect(try await itemIdentifiers(of: "pack") == ["stove"])
    }

    @Test func moveItemReordersWithinTheComponent() async throws {
        let map = ChecklistItem(identifier: "map", title: "Map")
        try await repository.createChecklist(checklist("pack", items: [tent, stove, map]))

        try await repository.moveItem(identifier: "map", inComponentWithIdentifier: "pack", to: 0)

        #expect(try await itemIdentifiers(of: "pack") == ["map", "tent", "stove"])
    }

    @Test func moveItemThrowsWhenComponentOrItemIsMissing() async throws {
        try await repository.createChecklist(checklist("pack", items: [tent]))

        await #expect(throws: ChecklistError.componentNotFound(identifier: "nope")) {
            try await repository.moveItem(identifier: "tent", inComponentWithIdentifier: "nope", to: 0)
        }
        await #expect(throws: ChecklistError.itemNotFound(identifier: "stove")) {
            try await repository.moveItem(identifier: "stove", inComponentWithIdentifier: "pack", to: 0)
        }
    }
}
