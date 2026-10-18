//
//  EventListLocalCacheRepositoryTests.swift
//  ServicesFactoryTests
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListLocalCacheRepositoryTests {
    private func makeRepository() throws -> EventListLocalCacheRepository {
        let database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        return EventListLocalCacheRepository(database: database)
    }

    private func makePackingList() -> List {
        List(
            identifier: "pack",
            title: "Packing",
            fields: [.weight],
            items: [
                ListItem(identifier: "tent", name: "Tent", weight: Measurement(value: 1500, unit: .grams)),
                ListItem(identifier: "stove", name: "Stove", weight: Measurement(value: 300, unit: .grams))
            ]
        )
    }

    @Test func allListsIsEmptyWhenNothingIsCached() async throws {
        let repository = try makeRepository()

        #expect(try await repository.allLists().firstValue().isEmpty)
    }

    @Test func allListsEmitsAgainWhenListsChange() async throws {
        let repository = try makeRepository()
        var iterator = repository.allLists().makeAsyncIterator()

        let initial = try await iterator.next()
        try await repository.createList(makePackingList())
        let updated = try await iterator.next()

        #expect(initial?.isEmpty == true)
        #expect(updated?.map(\.identifier) == ["pack"])
    }

    @Test func newSubscriptionReceivesLatestLists() async throws {
        let repository = try makeRepository()
        try await repository.createList(makePackingList())

        let first = try await repository.allLists().firstValue()
        let second = try await repository.allLists().firstValue()

        #expect(first.map(\.identifier) == ["pack"])
        #expect(second.map(\.identifier) == ["pack"])
    }

    @Test func storedListRoundTripsThroughPublicModel() async throws {
        let repository = try makeRepository()

        try await repository.store([makePackingList()])
        let lists = try await repository.allLists().firstValue()

        #expect(lists.count == 1)
        #expect(lists[0].identifier == "pack")
        #expect(lists[0].title == "Packing")
        #expect(lists[0].fields == [.weight])
        #expect(lists[0].items.map(\.identifier) == ["tent", "stove"])
        #expect(lists[0].items[0].weight == Measurement(value: 1500, unit: .grams))
    }

    @Test func storingSameListIdentifierReplacesPreviousContents() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingList()])

        let replacement = List(
            identifier: "pack",
            title: "Renamed",
            items: [ListItem(identifier: "map", name: "Map")]
        )
        try await repository.store([replacement])
        let lists = try await repository.allLists().firstValue()

        #expect(lists.count == 1)
        #expect(lists[0].title == "Renamed")
        #expect(lists[0].fields.isEmpty)
        #expect(lists[0].items.map(\.identifier) == ["map"])
    }

    @Test func allEventsIsEmptyWhenNothingIsCached() async throws {
        let repository = try makeRepository()

        #expect(try await repository.allEvents().firstValue().isEmpty)
    }

    @Test func allEventsBuildsEventsFromStoredRows() async throws {
        let database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        let repository = EventListLocalCacheRepository(database: database)
        let list = makePackingList()
        let event = Event(identifier: "trip", title: "Trip", lists: [list])
        try await repository.store([list])
        try await database.insert([EventRecord(event)])
        try await database.insert(EventListRecord.records(for: event))

        let events = try await repository.allEvents().firstValue()

        #expect(events.count == 1)
        #expect(events[0].title == "Trip")
        #expect(events[0].lists.map(\.identifier) == ["pack"])
        #expect(events[0].lists[0].items.map(\.identifier) == ["tent", "stove"])
    }

    @Test func storingOneListLeavesOtherCachedListsUntouched() async throws {
        let repository = try makeRepository()
        try await repository.store([makePackingList()])

        try await repository.store([List(identifier: "other", title: "Other")])
        let identifiers = try await repository.allLists().firstValue().map(\.identifier)

        #expect(Set(identifiers) == ["pack", "other"])
    }
}
