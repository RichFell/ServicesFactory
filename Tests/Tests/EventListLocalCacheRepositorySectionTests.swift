//
//  EventListLocalCacheRepositorySectionTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListLocalCacheRepositorySectionTests {
    private let database: SQLiteDatabase
    private let repository: EventListLocalCacheRepository

    init() throws {
        database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = EventListLocalCacheRepository(database: database)
    }

    private let tent = ListItem(identifier: "tent", name: "Tent")
    private let stove = ListItem(identifier: "stove", name: "Stove")

    private func makeList() async throws {
        let list = List(
            identifier: "pack",
            sections: [ListSection(identifier: "shelter", title: "Shelter", items: [tent])]
        )
        try await repository.createList(list)
    }

    private func sections() async throws -> [ListSection] {
        try await repository.allLists().firstValue().first?.sections ?? []
    }

    @Test func addSectionAppendsItWithItsItems() async throws {
        try await makeList()

        try await repository.addSection(
            ListSection(identifier: "kitchen", title: "Kitchen", items: [stove, tent]),
            toListWithIdentifier: "pack"
        )

        let stored = try await sections()
        #expect(stored.map(\.identifier) == ["shelter", "kitchen"])
        #expect(stored[1].items.map(\.identifier) == ["stove", "tent"])
        #expect(try await database.fetchAll(ListItemRecord.self).count == 2)
    }

    @Test func addSectionThrowsWhenListIsMissing() async {
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.addSection(ListSection(identifier: "s"), toListWithIdentifier: "nope")
        }
    }

    @Test func updateSectionChangesTheTitleButNotTheItems() async throws {
        try await makeList()

        try await repository.updateSection(ListSection(identifier: "shelter", title: "Camp"))

        let stored = try #require(try await sections().first)
        #expect(stored.title == "Camp")
        #expect(stored.items.map(\.identifier) == ["tent"])
    }

    @Test func updateSectionThrowsWhenSectionIsMissing() async {
        await #expect(throws: EventListError.sectionNotFound(identifier: "nope")) {
            try await repository.updateSection(ListSection(identifier: "nope"))
        }
    }

    @Test func deleteSectionKeepsItsItemsAndOtherSections() async throws {
        try await makeList()
        try await repository.addSection(ListSection(identifier: "kitchen", items: [tent]), toListWithIdentifier: "pack")

        try await repository.deleteSection(identifier: "shelter")

        #expect(try await sections().map(\.identifier) == ["kitchen"])
        #expect(try await sections().first?.items.map(\.identifier) == ["tent"])
        #expect(try await database.fetchAll(ListItemRecord.self).count == 1)
    }

    @Test func itemValuesAreReplacedWhenAnItemIsUpdated() async throws {
        let priced = ListItem(identifier: "tent", name: "Tent", values: [.price: .price(5)])
        try await repository.createList(List(identifier: "pack", items: [priced]))

        try await repository.updateItem(
            ListItem(identifier: "tent", name: "Tent", values: [.weight: .weight(Measurement(value: 1, unit: .kilograms))])
        )

        let stored = try #require(try await repository.allLists().firstValue().first?.items.first)
        #expect(stored.price == nil)
        #expect(stored.weight == Measurement(value: 1000, unit: .grams))
    }
}
