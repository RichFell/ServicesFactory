//
//  EventRunListFieldRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

/// A ``ListField`` a snapshotted list declared when a run started.
@Table("eventRunListFields")
struct EventRunListFieldRecord: Equatable, Sendable {
    let runID: String
    let listID: String
    /// The ``ListField`` raw value.
    let field: String

    /// Creates one row per field declared by each list in `run`.
    static func records(for run: EventRun) -> [EventRunListFieldRecord] {
        run.lists.flatMap { list in
            list.fields.map { EventRunListFieldRecord(runID: run.identifier, listID: list.identifier, field: $0.rawValue) }
        }
    }
}
