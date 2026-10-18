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
/// The run's list snapshot lives in ``EventRunListRecord``, ``EventRunListFieldRecord`` and
/// ``EventRunItemRecord``; its completions in ``EventRunCompletedItemRecord``.
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

    /// Creates a row from a public ``EventRun``.
    init(_ run: EventRun) {
        id = run.identifier
        eventID = run.eventIdentifier
        title = run.title
        isComplete = run.isComplete
        startedAt = run.startedAt.timeIntervalSince1970
        completedAt = run.completedAt?.timeIntervalSince1970
    }

    /// Rebuilds the public ``EventRun`` from this row, its snapshot `lists` and its completed item rows.
    func makeRun(lists: [List], completedItems: [EventRunCompletedItemRecord]) -> EventRun {
        EventRun(
            identifier: id,
            eventIdentifier: eventID,
            title: title,
            lists: lists,
            completedItemIdentifiers: Set(completedItems.map(\.itemID)),
            isComplete: isComplete,
            startedAt: Date(timeIntervalSince1970: startedAt),
            completedAt: completedAt.map { Date(timeIntervalSince1970: $0) }
        )
    }
}
