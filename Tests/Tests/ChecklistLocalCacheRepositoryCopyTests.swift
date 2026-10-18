//
//  ChecklistLocalCacheRepositoryCopyTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/18/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistLocalCacheRepositoryCopyTests {
    private let database: SQLiteDatabase
    private let repository: ChecklistLocalCacheRepository

    init() throws {
        database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = ChecklistLocalCacheRepository(database: database)
    }

    private let tent = ChecklistItem(
        identifier: "tent",
        title: "Tent",
        weight: Measurement(value: 1500, unit: .grams),
        price: Decimal(string: "199.99"),
        imageData: Data([1, 2, 3]),
        isCompleted: true
    )

    /// Creates a two-component "pack" checklist whose tent is already completed.
    private func makePack() async throws {
        let pack = Checklist(
            identifier: "pack",
            title: "Packing",
            type: .weight,
            isFlatList: false,
            components: [
                ChecklistComponent(identifier: "shelter", title: "Shelter", items: [tent]),
                ChecklistComponent(identifier: "kitchen", title: "Kitchen", items: [ChecklistItem(identifier: "stove", title: "Stove")])
            ]
        )
        try await repository.createChecklist(pack)
    }

    private func checklist(_ identifier: String) async throws -> Checklist? {
        try await repository.allChecklists().firstValue().first { $0.identifier == identifier }
    }

    @Test func copyChecklistStoresAnIndependentCopyWithNewIdentifiersAndNothingCompleted() async throws {
        try await makePack()

        let copy = try await repository.copyChecklist(identifier: "pack", title: "Trip 2")
        let stored = try #require(try await checklist(copy.identifier))
        let original = try #require(try await checklist("pack"))

        #expect(copy.identifier != "pack")
        #expect(stored.title == "Trip 2")
        #expect(stored.type == .weight)
        #expect(!stored.isFlatList)
        #expect(stored.components.map(\.title) == ["Shelter", "Kitchen"])
        #expect(stored.items.map(\.title) == ["Tent", "Stove"])
        #expect(stored.items[0].weight == Measurement(value: 1500, unit: .grams))
        #expect(stored.items[0].price == Decimal(string: "199.99"))
        #expect(stored.items[0].imageData == Data([1, 2, 3]))
        #expect(stored.items.allSatisfy { !$0.isCompleted })
        #expect(Set(stored.items.map(\.identifier)).isDisjoint(with: original.items.map(\.identifier)))
        #expect(Set(stored.components.map(\.identifier)).isDisjoint(with: original.components.map(\.identifier)))
        #expect(original.items[0].isCompleted)
    }

    @Test func editingACopyNeverChangesTheOriginalAndViceVersa() async throws {
        try await makePack()
        let copy = try await repository.copyChecklist(identifier: "pack", title: "Trip 2")
        let copiedTent = try #require(copy.items.first)

        try await repository.updateItem(
            ChecklistItem(identifier: copiedTent.identifier, title: "Renamed tent", weight: nil)
        )
        try await repository.setItem(identifier: copiedTent.identifier, isCompleted: true)
        try await repository.deleteItem(identifier: "stove")
        try await repository.updateComponent(ChecklistComponent(identifier: "shelter", title: "Camp"))

        let original = try #require(try await checklist("pack"))
        let stored = try #require(try await checklist(copy.identifier))
        #expect(original.items.map(\.title) == ["Tent"])
        #expect(original.items[0].weight == Measurement(value: 1500, unit: .grams))
        #expect(stored.items.map(\.title) == ["Renamed tent", "Stove"])
        #expect(stored.components.map(\.title) == ["Shelter", "Kitchen"])
    }

    @Test func deletingTheOriginalLeavesTheCopyIntact() async throws {
        try await makePack()
        let copy = try await repository.copyChecklist(identifier: "pack", title: "Trip 2")

        try await repository.deleteChecklist(identifier: "pack")

        #expect(try await checklist(copy.identifier)?.items.map(\.title) == ["Tent", "Stove"])
    }

    @Test func copyChecklistThrowsWhenMissing() async {
        await #expect(throws: ChecklistError.checklistNotFound(identifier: "nope")) {
            try await repository.copyChecklist(identifier: "nope", title: "Copy")
        }
    }

    @Test func copyComponentAddsAnIndependentCopyToAnotherChecklist() async throws {
        try await makePack()
        let target = Checklist(identifier: "weekend", isFlatList: false, components: [])
        try await repository.createChecklist(target)

        let copy = try await repository.copyComponent(identifier: "kitchen", toChecklistWithIdentifier: "weekend")
        try await repository.updateItem(ChecklistItem(identifier: copy.items[0].identifier, title: "Camp stove"))

        let weekend = try #require(try await checklist("weekend"))
        let pack = try #require(try await checklist("pack"))
        #expect(weekend.components.map(\.identifier) == [copy.identifier])
        #expect(weekend.components.first?.title == "Kitchen")
        #expect(weekend.items.map(\.title) == ["Camp stove"])
        #expect(pack.items.map(\.title) == ["Tent", "Stove"])
    }

    @Test func copiedComponentsAppendAfterExistingOnesAndResetCompletion() async throws {
        try await makePack()
        try await repository.createChecklist(Checklist(identifier: "weekend", isFlatList: false, components: []))

        _ = try await repository.copyComponent(identifier: "shelter", toChecklistWithIdentifier: "weekend")
        _ = try await repository.copyComponent(identifier: "kitchen", toChecklistWithIdentifier: "weekend")

        let weekend = try #require(try await checklist("weekend"))
        #expect(weekend.components.map(\.title) == ["Shelter", "Kitchen"])
        #expect(weekend.items.allSatisfy { !$0.isCompleted })
    }

    @Test func copyComponentThrowsWhenComponentOrChecklistIsMissingOrFlat() async throws {
        try await makePack()
        try await repository.createChecklist(Checklist(identifier: "flat", items: []))

        await #expect(throws: ChecklistError.componentNotFound(identifier: "nope")) {
            try await repository.copyComponent(identifier: "nope", toChecklistWithIdentifier: "pack")
        }
        await #expect(throws: ChecklistError.checklistNotFound(identifier: "nope")) {
            try await repository.copyComponent(identifier: "kitchen", toChecklistWithIdentifier: "nope")
        }
        await #expect(throws: ChecklistError.flatChecklistRequiresOneComponent(identifier: "flat")) {
            try await repository.copyComponent(identifier: "kitchen", toChecklistWithIdentifier: "flat")
        }
    }
}
