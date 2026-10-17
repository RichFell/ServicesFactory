//
//  Event.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// An event that uses one or more ``List``s and tracks its own completion of their items.
public struct Event: Sendable {
    /// The unique identifier of the event.
    public let identifier: String
    /// The display title of the event.
    public let title: String
    /// The identifiers of the lists the event is using. A list can be used by many events.
    public let lists: [List]
    /// The identifiers of the ``ListItem``s completed for this event.
    public let completedItemIdentifiers: Set<String>
    /// Whether the event has been completed.
    public let isComplete: Bool

    /// Creates an event with the given identifier, title, list identifiers, completed items, and completion state.
    public init(
        identifier: String,
        title: String,
        lists: [List] = [],
        completedItemIdentifiers: Set<String> = [],
        isComplete: Bool = false
    ) {
        self.identifier = identifier
        self.title = title
        self.lists = lists
        self.completedItemIdentifiers = completedItemIdentifiers
        self.isComplete = isComplete
    }

    /// Returns whether `item` has been completed for this event.
    public func isCompleted(_ item: ListItem) -> Bool {
        completedItemIdentifiers.contains(item.identifier)
    }
}
