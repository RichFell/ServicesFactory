//
//  EventListRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/16/26.
//

import SQLiteData

/// The join row linking an event to a list it uses. A list can be used by many events.
@Table("eventLists")
struct EventListRecord: Equatable, Sendable {
    let eventID: String
    let listID: String
    /// The list's index within the event, preserving order.
    var position: Int

    /// Creates one row per list used by `event`, in order.
    static func records(for event: Event) -> [EventListRecord] {
        event.lists.enumerated().map { index, list in
            EventListRecord(eventID: event.identifier, listID: list.identifier, position: index)
        }
    }
}
