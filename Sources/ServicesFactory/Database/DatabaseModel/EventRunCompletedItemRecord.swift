//
//  EventRunCompletedItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The row recording that an item was completed in a run.
@Table("eventRunCompletedItems")
struct EventRunCompletedItemRecord: Equatable, Sendable {
    let runID: String
    let itemID: String

    /// Creates one row per item completed in `run`.
    static func records(for run: EventRun) -> [EventRunCompletedItemRecord] {
        run.completedItemIdentifiers.map {
            EventRunCompletedItemRecord(runID: run.identifier, itemID: $0)
        }
    }
}
