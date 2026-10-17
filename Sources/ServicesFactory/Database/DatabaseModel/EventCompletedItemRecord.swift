//
//  EventCompletedItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The join row recording that an item was completed for an event.
@Table("eventCompletedItems")
struct EventCompletedItemRecord: Equatable, Sendable {
    let eventID: String
    let itemID: String

    /// Creates one row per item completed for `event`.
    static func records(for event: Event) -> [EventCompletedItemRecord] {
        event.completedItemIdentifiers.map {
            EventCompletedItemRecord(eventID: event.identifier, itemID: $0)
        }
    }
}
