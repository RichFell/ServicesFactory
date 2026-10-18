//
//  ChecklistLocalCacheRepositoryComponentTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistLocalCacheRepositoryComponentTests {
    private let database: SQLiteDatabase
    private let repository: ChecklistLocalCacheRepository

    init() throws {
        database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = ChecklistLocalCacheRepository(database: database)
    }

    private let tent = ChecklistItem(identifier: "tent", title: "Tent")
    private let stove = ChecklistItem(identifier: "stove", title: "Stove")

    private func makeMultiComponentChecklist() async throws {
        let pack = Checklist(
            identifier: "pack",
            title: "Packing",
            type: .weight,
            isFlatList: false,
            components: [ChecklistComponent(identifier: "shelter", title: "Shelter", items: [tent])]
        )
        try await repository.createChecklist(pack)
    }

    private func components(of identifier: String = "pack") async throws -> [ChecklistComponent] {
        try await repository.allChecklists().firstValue().first { $0.identifier == identifier }?.components ?? []
    }

    @Test func addComponentAppendsItWithItsItems() async throws {
        try await makeMultiComponentChecklist()

        try await repository.addComponent(
            ChecklistComponent(identifier: "kitchen", title: "Kitchen", items: [stove]),
            toChecklistWithIdentifier: "pack"
        )

        let stored = try await components()
        #expect(stored.map(\.identifier) == ["shelter", "kitchen"])
        #expect(stored[1].items.map(\.identifier) == ["stove"])
    }

    @Test func addComponentThrowsWhenChecklistIsMissingOrFlat() async throws {
        try await repository.createChecklist(Checklist(identifier: "flat", items: [tent]))

        await #expect(throws: ChecklistError.checklistNotFound(identifier: "nope")) {
            try await repository.addComponent(ChecklistComponent(identifier: "c"), toChecklistWithIdentifier: "nope")
        }
        await #expect(throws: ChecklistError.flatChecklistRequiresOneComponent(identifier: "flat")) {
            try await repository.addComponent(ChecklistComponent(identifier: "c"), toChecklistWithIdentifier: "flat")
        }
    }

    @Test func updateComponentChangesTheTitleButNotTheItems() async throws {
        try await makeMultiComponentChecklist()

        try await repository.updateComponent(ChecklistComponent(identifier: "shelter", title: "Camp"))

        let stored = try #require(try await components().first)
        #expect(stored.title == "Camp")
        #expect(stored.items.map(\.identifier) == ["tent"])
    }

    @Test func updateComponentThrowsWhenComponentIsMissing() async {
        await #expect(throws: ChecklistError.componentNotFound(identifier: "nope")) {
            try await repository.updateComponent(ChecklistComponent(identifier: "nope"))
        }
    }

    @Test func deleteComponentRemovesItsItemsAndKeepsOtherComponents() async throws {
        try await makeMultiComponentChecklist()
        try await repository.addComponent(ChecklistComponent(identifier: "kitchen", items: [stove]), toChecklistWithIdentifier: "pack")

        try await repository.deleteComponent(identifier: "shelter")

        #expect(try await components().map(\.identifier) == ["kitchen"])
        #expect(try await database.fetchAll(ChecklistItemRecord.self).map(\.id) == ["stove"])
    }

    @Test func deleteComponentIsRefusedForTheOnlyComponentOfAFlatChecklist() async throws {
        try await repository.createChecklist(Checklist(identifier: "flat", items: [tent]))

        await #expect(throws: ChecklistError.flatChecklistRequiresOneComponent(identifier: "flat")) {
            try await repository.deleteComponent(identifier: "flat")
        }
        #expect(try await components(of: "flat").count == 1)
    }

    @Test func deleteComponentDoesNothingWhenMissing() async throws {
        try await repository.deleteComponent(identifier: "nope")
    }
}
