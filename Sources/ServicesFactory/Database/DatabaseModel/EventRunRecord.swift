//
//  EventRunRecord.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation
import SQLiteData

/// The stored row for an ``EventRun``.
///
/// The run is self-contained: `snapshot` holds its lists as JSON (see ``EventRunSnapshot``) and
/// `eventID` is a plain reference with no foreign key, so a run outlives its event. Its
/// completions live in ``EventRunCompletedItemRecord``.
@Table("eventRuns")
struct EventRunRecord: Equatable, Sendable {
    let id: String
    let eventID: String
    var title: String
    var isComplete: Bool
    /// Seconds since 1970 when the run started.
    var startedAt: Double
    /// Seconds since 1970 when the run was completed, or `nil` while in progress.
    var completedAt: Double?
    /// The run's lists as JSON.
    var snapshot: String

    /// Creates a row from a public ``EventRun``, encoding its lists.
    init(_ run: EventRun) throws {
        id = run.identifier
        eventID = run.eventIdentifier
        title = run.title
        isComplete = run.isComplete
        startedAt = run.startedAt.timeIntervalSince1970
        completedAt = run.completedAt?.timeIntervalSince1970
        snapshot = try EventRunSnapshot(lists: run.lists).json()
    }

    /// Rebuilds the public ``EventRun`` from this row, decoding its lists, and its completed item rows.
    func makeRun(completedItems: [EventRunCompletedItemRecord]) throws -> EventRun {
        EventRun(
            identifier: id,
            eventIdentifier: eventID,
            title: title,
            lists: try EventRunSnapshot.decode(json: snapshot).makeLists(),
            completedItemIdentifiers: completedItems.reduce(into: [:]) { result, record in
                result[record.listID, default: []].insert(record.itemID)
            },
            isComplete: isComplete,
            startedAt: Date(timeIntervalSince1970: startedAt),
            completedAt: completedAt.map { Date(timeIntervalSince1970: $0) }
        )
    }
}
