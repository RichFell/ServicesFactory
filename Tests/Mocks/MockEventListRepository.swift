//
//  MockEventListRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
@testable import ServicesFactory

/// An ``EventListWritableRepository`` stand-in that returns canned results or throws a canned error.
///
/// Edits are not applied; each one is recorded in ``calls`` so tests can check what was delegated.
struct MockEventListRepository: EventListWritableRepository {
    var lists: [List] = []
    var events: [Event] = []
    var runs: [EventRun] = []
    var error: (any Error & Sendable)?
    let calls = Calls()

    func allLists() -> AsyncThrowingStream<[List], any Error> {
        stream(of: lists)
    }

    func allEvents() -> AsyncThrowingStream<[Event], any Error> {
        stream(of: events)
    }

    func createList(_ list: List) async throws {
        try await record("createList(\(list.identifier))")
    }

    func updateList(_ list: List) async throws {
        try await record("updateList(\(list.identifier))")
    }

    func deleteList(identifier: String) async throws {
        try await record("deleteList(\(identifier))")
    }

    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws {
        try await record("addItem(\(item.identifier), \(listIdentifier))")
    }

    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws {
        try await record("removeItem(\(identifier), \(listIdentifier))")
    }

    func updateItem(_ item: ListItem) async throws {
        try await record("updateItem(\(item.identifier))")
    }

    func deleteItem(identifier: String) async throws {
        try await record("deleteItem(\(identifier))")
    }

    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws {
        try await record("moveItem(\(identifier), \(listIdentifier), \(position))")
    }

    func allEventRuns() -> AsyncThrowingStream<[EventRun], any Error> {
        stream(of: runs)
    }

    func createEvent(_ event: Event) async throws {
        try await record("createEvent(\(event.identifier))")
    }

    func updateEvent(_ event: Event) async throws {
        try await record("updateEvent(\(event.identifier))")
    }

    func deleteEvent(identifier: String) async throws {
        try await record("deleteEvent(\(identifier))")
    }

    func startRun(
        ofEventWithIdentifier eventIdentifier: String,
        identifier: String,
        startedAt: Date
    ) async throws -> EventRun {
        try await record("startRun(\(eventIdentifier), \(identifier))")
        return EventRun(identifier: identifier, eventIdentifier: eventIdentifier, title: "", startedAt: startedAt)
    }

    func setItem(
        identifier: String,
        isCompleted: Bool,
        inRunWithIdentifier runIdentifier: String
    ) async throws {
        try await record("setItem(\(identifier), \(isCompleted), \(runIdentifier))")
    }

    func setRun(
        identifier: String,
        isComplete: Bool,
        at date: Date
    ) async throws {
        try await record("setRun(\(identifier), \(isComplete))")
    }

    func deleteRun(identifier: String) async throws {
        try await record("deleteRun(\(identifier))")
    }

    /// A stream that yields `value` once, or finishes with the canned error.
    private func stream<Value: Sendable>(of value: Value) -> AsyncThrowingStream<Value, any Error> {
        let error = error
        return AsyncThrowingStream { continuation in
            if let error {
                continuation.finish(throwing: error)
            } else {
                continuation.yield(value)
                continuation.finish()
            }
        }
    }

    private func record(_ call: String) async throws {
        if let error { throw error }
        await calls.append(call)
    }
}

extension MockEventListRepository {
    /// The edits received, in order. An actor so the mock stays `Sendable`.
    actor Calls {
        private(set) var values: [String] = []

        func append(_ call: String) {
            values.append(call)
        }
    }
}
