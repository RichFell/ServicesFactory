//
//  ChecklistLocalCacheRepositoryTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct ChecklistLocalCacheRepositoryTests {
    private func makeRepository() throws -> ChecklistLocalCacheRepository {
        let database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        return ChecklistLocalCacheRepository(database: database)
    }

    private func makePackingChecklist() -> Checklist {
        Checklist(
            identifier: "pack",
            title: "Packing",
            type: .weight,
            items: [
                ChecklistItem(identifier: "tent", title: "Tent", weight: Measurement(value: 1500, unit: .grams)),
                ChecklistItem(identifier: "stove", title: "Stove")
            ]
        )
    }

    @Test func allChecklistsIsEmptyWhenNothingIsCached() async throws {
        let repository = try makeRepository()

        #expect(try await repository.allChecklists().firstValue().isEmpty)
    }

    @Test func allChecklistsEmitsAgainWhenChecklistsChange() async throws {
        let repository = try makeRepository()
        var iterator = repository.allChecklists().makeAsyncIterator()

        let initial = try await iterator.next()
        try await repository.store([makePackingChecklist()])
        let updated = try await iterator.next()

        #expect(initial?.isEmpty == true)
        #expect(updated?.map(\.identifier) == ["pack"])
    }

    @Test func newSubscriptionReceivesLatestChecklists() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingChecklist()])

        #expect(try await repository.allChecklists().firstValue().map(\.identifier) == ["pack"])
    }

    @Test func storedChecklistRoundTripsThroughPublicModel() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingChecklist()])

        let checklist = try #require(try await repository.allChecklists().firstValue().first)

        #expect(checklist.title == "Packing")
        #expect(checklist.type == .weight)
        #expect(checklist.isFlatList)
        #expect(checklist.items.map(\.identifier) == ["tent", "stove"])
        #expect(checklist.items[0].weight == Measurement(value: 1500, unit: .grams))
        #expect(checklist.items[1].weight == nil)
    }

    @Test func storingSameIdentifierReplacesPreviousContents() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingChecklist()])

        try await repository.store([Checklist(identifier: "pack", title: "New", items: [ChecklistItem(identifier: "map", title: "Map")])])
        let checklists = try await repository.allChecklists().firstValue()

        #expect(checklists.count == 1)
        #expect(checklists[0].title == "New")
        #expect(checklists[0].items.map(\.identifier) == ["map"])
    }

    @Test func storingOneChecklistLeavesOtherCachedChecklistsUntouched() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingChecklist()])

        try await repository.store([Checklist(identifier: "other", items: [ChecklistItem(identifier: "x", title: "X")])])

        #expect(Set(try await repository.allChecklists().firstValue().map(\.identifier)) == ["pack", "other"])
    }
}
