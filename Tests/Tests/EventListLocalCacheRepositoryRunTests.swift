//
//  EventListLocalCacheRepositoryRunTests.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import Testing
@testable import ServicesFactory

struct EventListLocalCacheRepositoryRunTests {
    private let repository: EventListLocalCacheRepository

    init() throws {
        let database = try SQLiteDatabase(location: .inMemory, migrations: SQLiteDatabase.Migration.all)
        repository = EventListLocalCacheRepository(database: database)
    }

    private let tent = ListItem(
        identifier: "tent",
        name: "Tent",
        values: [.weight: .weight(Measurement(value: 1500, unit: .grams)), .price: .price(Decimal(string: "199.99")!)]
    )
    private let stove = ListItem(identifier: "stove", name: "Stove")

    /// Creates a "pack" list with two sections and a "trip" event using it.
    private func makeTrip() async throws {
        let pack = List(
            identifier: "pack",
            title: "Packing",
            fields: [.weight, .price],
            sections: [
                ListSection(identifier: "shelter", title: "Shelter", items: [tent]),
                ListSection(identifier: "kitchen", title: "Kitchen", items: [stove])
            ]
        )
        try await repository.createList(pack)
        try await repository.createEvent(Event(identifier: "trip", title: "Trip", lists: [pack]))
    }

    @discardableResult
    private func startRun(_ identifier: String, at date: Date = Date()) async throws -> EventRun {
        try await repository.startRun(
            ofEventWithIdentifier: "trip",
            identifier: identifier,
            startedAt: date
        )
    }

    private func run(_ identifier: String) async throws -> EventRun? {
        try await repository.allEventRuns().firstValue().first { $0.identifier == identifier }
    }

    private func complete(_ item: String, inList list: String = "pack", ofRun run: String) async throws {
        try await repository.setItem(
            identifier: item,
            isCompleted: true,
            inListWithIdentifier: list,
            inRunWithIdentifier: run
        )
    }

    @Test func startRunSnapshotsSectionsFieldsAndValues() async throws {
        try await makeTrip()

        let started = try await startRun("run")
        let stored = try #require(try await run("run"))
        let list = try #require(stored.lists.first)

        #expect(started.lists.map(\.identifier) == ["pack"])
        #expect(stored.eventIdentifier == "trip")
        #expect(stored.title == "Trip")
        #expect(list.title == "Packing")
        #expect(list.fields == [.weight, .price])
        #expect(list.sections.map(\.title) == ["Shelter", "Kitchen"])
        #expect(list.items.map(\.identifier) == ["tent", "stove"])
        #expect(list.items[0].weight == Measurement(value: 1500, unit: .grams))
        #expect(list.items[0].price == Decimal(string: "199.99"))
        #expect(!stored.isComplete)
        #expect(stored.completedItemIdentifiers.isEmpty)
    }

    @Test func editingLiveListsAndEventDoesNotChangeAnExistingRun() async throws {
        try await makeTrip()
        try await startRun("run")

        try await repository.updateItem(ListItem(identifier: "tent", name: "Big Tent"))
        try await repository.addItem(ListItem(identifier: "map", name: "Map"), toSectionWithIdentifier: "shelter")
        try await repository.removeItem(identifier: "stove", fromSectionWithIdentifier: "kitchen")
        try await repository.deleteSection(identifier: "kitchen")
        try await repository.updateList(List(identifier: "pack", title: "Renamed"))
        try await repository.updateEvent(Event(identifier: "trip", title: "Renamed Trip"))

        let stored = try #require(try await run("run"))
        #expect(stored.title == "Trip")
        #expect(stored.lists.first?.title == "Packing")
        #expect(stored.lists.first?.sections.map(\.title) == ["Shelter", "Kitchen"])
        #expect(stored.lists.first?.items.map(\.name) == ["Tent", "Stove"])
    }

    @Test func deletingLiveListAndItemsKeepsTheRunSnapshot() async throws {
        try await makeTrip()
        try await startRun("run")

        try await repository.deleteItem(identifier: "tent")
        try await repository.deleteList(identifier: "pack")

        #expect(try await run("run")?.lists.first?.items.map(\.identifier) == ["tent", "stove"])
    }

    @Test func deletingTheEventKeepsItsRuns() async throws {
        try await makeTrip()
        try await startRun("run")

        try await repository.deleteEvent(identifier: "trip")

        #expect(try await repository.allEvents().firstValue().isEmpty)
        #expect(try await run("run")?.eventIdentifier == "trip")
        #expect(try await run("run")?.lists.count == 1)
    }

    @Test func runsOfTheSameEventTrackCompletionSeparately() async throws {
        try await makeTrip()
        try await startRun("first")
        try await startRun("second")

        try await complete("tent", ofRun: "first")

        #expect(try await run("first")?.completedItemIdentifiers == ["pack": ["tent"]])
        #expect(try await run("second")?.completedItemIdentifiers.isEmpty == true)
    }

    @Test func eachListInARunHasItsOwnCheckmarkForASharedItem() async throws {
        let one = List(identifier: "one", items: [tent])
        let two = List(identifier: "two", items: [tent])
        try await repository.createList(one)
        try await repository.createList(two)
        try await repository.createEvent(Event(identifier: "trip", title: "Trip", lists: [one, two]))
        try await startRun("run")

        try await complete("tent", inList: "one", ofRun: "run")

        let stored = try #require(try await run("run"))
        #expect(stored.completedItemIdentifiers == ["one": ["tent"]])
        #expect(stored.isCompleted(tent, in: one))
        #expect(!stored.isCompleted(tent, in: two))
    }

    @Test func settingAnItemNotCompletedClearsIt() async throws {
        try await makeTrip()
        try await startRun("run")
        try await complete("tent", ofRun: "run")
        try await complete("tent", ofRun: "run")

        try await repository.setItem(
            identifier: "tent",
            isCompleted: false,
            inListWithIdentifier: "pack",
            inRunWithIdentifier: "run"
        )

        #expect(try await run("run")?.completedItemIdentifiers.isEmpty == true)
    }

    @Test func completingARunRecordsTheDateAndReopeningClearsIt() async throws {
        try await makeTrip()
        try await startRun("run")
        let date = Date(timeIntervalSince1970: 5_000)

        try await repository.setRun(identifier: "run", isComplete: true, at: date)
        #expect(try await run("run")?.isComplete == true)
        #expect(try await run("run")?.completedAt == date)

        try await repository.setRun(identifier: "run", isComplete: false, at: date)
        #expect(try await run("run")?.isComplete == false)
        #expect(try await run("run")?.completedAt == nil)
    }

    @Test func missingTargetsThrowNotFoundErrors() async throws {
        try await makeTrip()
        try await startRun("run")

        await #expect(throws: EventListError.eventNotFound(identifier: "nope")) {
            try await repository.startRun(ofEventWithIdentifier: "nope", identifier: "x", startedAt: Date())
        }
        await #expect(throws: EventListError.runNotFound(identifier: "nope")) {
            try await complete("tent", ofRun: "nope")
        }
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await complete("tent", inList: "nope", ofRun: "run")
        }
        await #expect(throws: EventListError.itemNotFound(identifier: "ghost")) {
            try await complete("ghost", ofRun: "run")
        }
        await #expect(throws: EventListError.runNotFound(identifier: "nope")) {
            try await repository.setRun(identifier: "nope", isComplete: true, at: Date())
        }
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.createEvent(Event(identifier: "e", title: "E", lists: [List(identifier: "nope")]))
        }
    }

    @Test func deletingARunKeepsTheEventAndItsOtherRuns() async throws {
        try await makeTrip()
        try await startRun("one")
        try await startRun("two")
        try await complete("tent", ofRun: "one")

        try await repository.deleteRun(identifier: "one")

        #expect(try await repository.allEventRuns().firstValue().map(\.identifier) == ["two"])
        #expect(try await repository.allEvents().firstValue().count == 1)
    }
}
