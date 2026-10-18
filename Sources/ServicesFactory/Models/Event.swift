//
//  Event.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A reusable event: a title and the ``List``s it uses.
///
/// An event holds no completion state. Each time it is carried out, an ``EventRun`` snapshots
/// its lists and tracks the completion of their items.
public struct Event: Sendable {
    /// The unique identifier of the event.
    public let identifier: String
    /// The display title of the event.
    public let title: String
    /// The lists the event uses, in order. A list can be used by many events.
    public let lists: [List]

    /// Creates an event with the given identifier, title and lists.
    public init(
        identifier: String,
        title: String,
        lists: [List] = []
    ) {
        self.identifier = identifier
        self.title = title
        self.lists = lists
    }
}
