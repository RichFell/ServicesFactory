//
//  EventRunCompletedItemRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// The row recording that an item was completed in one list of a run.
///
/// Completion is per list, so an item shared by two lists is completed separately in each.
@Table("eventRunCompletedItems")
struct EventRunCompletedItemRecord: Equatable, Sendable {
    let runID: String
    /// The identifier of the snapshotted list the item was completed in.
    let listID: String
    let itemID: String

    /// Creates one row per item completed in each list of `run`.
    static func records(for run: EventRun) -> [EventRunCompletedItemRecord] {
        run.completedItemIdentifiers.flatMap { listID, itemIDs in
            itemIDs.map { EventRunCompletedItemRecord(runID: run.identifier, listID: listID, itemID: $0) }
        }
    }
}
