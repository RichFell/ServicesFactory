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

    private let tent = ListItem(identifier: "tent", name: "Tent", weight: Measurement(value: 1500, unit: .grams))
    private let stove = ListItem(identifier: "stove", name: "Stove")

    /// Creates a "pack" list and a "trip" event using it.
    private func makeTrip() async throws {
        let pack = List(identifier: "pack", title: "Packing", fields: [.weight], items: [tent, stove])
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

    @Test func startRunSnapshotsListsFieldsAndItems() async throws {
        try await makeTrip()

        let started = try await startRun("run")
        let stored = try await run("run")

        #expect(started.lists.map(\.identifier) == ["pack"])
        #expect(stored?.eventIdentifier == "trip")
        #expect(stored?.title == "Trip")
        #expect(stored?.lists.first?.title == "Packing")
        #expect(stored?.lists.first?.fields == [.weight])
        #expect(stored?.lists.first?.items.map(\.identifier) == ["tent", "stove"])
        #expect(stored?.lists.first?.items.first?.weight == Measurement(value: 1500, unit: .grams))
        #expect(stored?.isComplete == false)
        #expect(stored?.completedItemIdentifiers == [])
    }

    @Test func editingLiveListsAndEventDoesNotChangeAnExistingRun() async throws {
        try await makeTrip()
        try await startRun("run")

        try await repository.updateItem(ListItem(identifier: "tent", name: "Big Tent"))
        try await repository.addItem(ListItem(identifier: "map", name: "Map"), toListWithIdentifier: "pack")
        try await repository.removeItem(identifier: "stove", fromListWithIdentifier: "pack")
        try await repository.updateList(List(identifier: "pack", title: "Renamed"))
        try await repository.updateEvent(Event(identifier: "trip", title: "Renamed Trip"))

        let stored = try await run("run")
        #expect(stored?.title == "Trip")
        #expect(stored?.lists.first?.title == "Packing")
        #expect(stored?.lists.first?.items.map(\.name) == ["Tent", "Stove"])
    }

    @Test func deletingLiveListAndItemsKeepsTheRunSnapshot() async throws {
        try await makeTrip()
        try await startRun("run")

        try await repository.deleteItem(identifier: "tent")
        try await repository.deleteList(identifier: "pack")

        let stored = try await run("run")
        #expect(stored?.lists.first?.items.map(\.identifier) == ["tent", "stove"])
    }

    @Test func runsOfTheSameEventTrackCompletionSeparately() async throws {
        try await makeTrip()
        try await startRun("first")
        try await startRun("second")

        try await repository.setItem(identifier: "tent", isCompleted: true, inRunWithIdentifier: "first")

        #expect(try await run("first")?.completedItemIdentifiers == ["tent"])
        #expect(try await run("second")?.completedItemIdentifiers == [])
    }

    @Test func settingAnItemNotCompletedClearsIt() async throws {
        try await makeTrip()
        try await startRun("run")
        try await repository.setItem(identifier: "tent", isCompleted: true, inRunWithIdentifier: "run")
        try await repository.setItem(identifier: "tent", isCompleted: true, inRunWithIdentifier: "run")

        try await repository.setItem(identifier: "tent", isCompleted: false, inRunWithIdentifier: "run")

        #expect(try await run("run")?.completedItemIdentifiers == [])
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
            try await repository.setItem(identifier: "tent", isCompleted: true, inRunWithIdentifier: "nope")
        }
        await #expect(throws: EventListError.itemNotFound(identifier: "ghost")) {
            try await repository.setItem(identifier: "ghost", isCompleted: true, inRunWithIdentifier: "run")
        }
        await #expect(throws: EventListError.runNotFound(identifier: "nope")) {
            try await repository.setRun(identifier: "nope", isComplete: true, at: Date())
        }
        await #expect(throws: EventListError.listNotFound(identifier: "nope")) {
            try await repository.createEvent(Event(identifier: "e", title: "E", lists: [List(identifier: "nope")]))
        }
    }

    @Test func deletingARunKeepsTheEventAndDeletingTheEventRemovesItsRuns() async throws {
        try await makeTrip()
        try await startRun("one")
        try await startRun("two")

        try await repository.deleteRun(identifier: "one")
        #expect(try await repository.allEventRuns().firstValue().map(\.identifier) == ["two"])
        #expect(try await repository.allEvents().firstValue().count == 1)

        try await repository.deleteEvent(identifier: "trip")
        #expect(try await repository.allEventRuns().firstValue().isEmpty)
        #expect(try await repository.allLists().firstValue().count == 1)
    }
}
