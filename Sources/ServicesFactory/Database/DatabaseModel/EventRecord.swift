//
//  EventRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The stored row for an ``Event``. Its lists live in ``EventListRecord``; its runs in ``EventRunRecord``.
@Table("events")
struct EventRecord: Equatable, Sendable {
    let id: String
    var title: String

    /// Creates a row from a public ``Event``.
    init(_ event: Event) {
        id = event.identifier
        title = event.title
    }

    /// Rebuilds the public ``Event`` from this row and its resolved `lists`.
    func makeEvent(lists: [List]) -> Event {
        Event(
            identifier: id,
            title: title,
            lists: lists
        )
    }
}
