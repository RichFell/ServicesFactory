//
//  EventRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for an ``Event``. Its lists and completed items live in ``EventListRecord`` and ``EventCompletedItemRecord``.
@Table("events")
struct EventRecord: Equatable, Sendable {
    let id: String
    var title: String
    var isComplete: Bool

    /// Creates a row from a public ``Event``.
    init(_ event: Event) {
        id = event.identifier
        title = event.title
        isComplete = event.isComplete
    }

    /// Rebuilds the public ``Event`` from this row, its resolved `lists`, and its completed item rows.
    func makeEvent(lists: [List], completedItems: [EventCompletedItemRecord]) -> Event {
        Event(
            identifier: id,
            title: title,
            lists: lists,
            completedItemIdentifiers: Set(completedItems.map(\.itemID)),
            isComplete: isComplete
        )
    }
}
