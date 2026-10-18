//
//  EventRun.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// One run of an ``Event``, with its own snapshot of the lists as they were when it started.
///
/// Later edits to the event, its lists or their items never change a run, so looking back at a
/// run shows exactly what was used at that time. A run outlives the event it came from.
public struct EventRun: Sendable {
    /// The unique identifier of the run.
    public let identifier: String
    /// The identifier of the ``Event`` this run was started from. The event may no longer exist.
    public let eventIdentifier: String
    /// The event's title when the run started.
    public let title: String
    /// The lists as they were when the run started, in order.
    public let lists: [List]
    /// The identifiers of the ``ListItem``s completed in this run, by list identifier.
    ///
    /// Each list tracks its own completion, so an item shared by two lists is completed separately in each.
    public let completedItemIdentifiers: [String: Set<String>]
    /// Whether the run has been marked completed.
    public let isComplete: Bool
    /// When the run started.
    public let startedAt: Date
    /// When the run was marked completed, or `nil` while it is in progress.
    public let completedAt: Date?

    /// Creates a run with the given snapshot, completion state and dates.
    public init(
        identifier: String,
        eventIdentifier: String,
        title: String,
        lists: [List] = [],
        completedItemIdentifiers: [String: Set<String>] = [:],
        isComplete: Bool = false,
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.identifier = identifier
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.lists = lists
        self.completedItemIdentifiers = completedItemIdentifiers
        self.isComplete = isComplete
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    /// Returns whether `item` has been completed in `list` for this run.
    public func isCompleted(_ item: ListItem, in list: List) -> Bool {
        completedItemIdentifiers[list.identifier]?.contains(item.identifier) ?? false
    }
}
