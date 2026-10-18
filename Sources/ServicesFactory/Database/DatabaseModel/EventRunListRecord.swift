//
//  EventRunListRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// A list as it was when a run started. Independent of the live ``ListRecord``, so later edits don't change it.
@Table("eventRunLists")
struct EventRunListRecord: Equatable, Sendable {
    let runID: String
    /// The identifier of the live list this was copied from.
    let listID: String
    var title: String
    /// The list's index within the run, preserving order.
    var position: Int

    /// Creates one row per list in `run`, in order.
    static func records(for run: EventRun) -> [EventRunListRecord] {
        run.lists.enumerated().map { index, list in
            EventRunListRecord(runID: run.identifier, listID: list.identifier, title: list.title, position: index)
        }
    }
}
