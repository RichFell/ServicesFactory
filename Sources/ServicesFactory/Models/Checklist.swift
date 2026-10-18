//
//  Checklist.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A checklist returned by a ``ChecklistService``.
///
/// A checklist owns its components and their items outright. Building a new checklist from an
/// existing one copies it, so each checklist can be edited and completed independently.
public struct Checklist: Sendable {
    /// The unique identifier of the checklist.
    public let identifier: String

    /// The title of the checklist.
    public let title: String

    /// What the checklist is for, which drives how its items are displayed.
    public let type: ChecklistType

    /// Whether the checklist is a single group of items rather than several titled components.
    public let isFlatList: Bool

    /// The components of the checklist, in order. A flat checklist has one.
    public let components: [ChecklistComponent]

    /// Every item of the checklist, in component order.
    public var items: [ChecklistItem] {
        components.flatMap(\.items)
    }

    /// Whether the checklist has items and all of them are completed.
    public var isComplete: Bool {
        let items = items
        return !items.isEmpty && items.allSatisfy(\.isCompleted)
    }

    /// Creates a checklist made of the given components.
    public init(
        identifier: String,
        title: String = "",
        type: ChecklistType = .standard,
        isFlatList: Bool = false,
        components: [ChecklistComponent]
    ) {
        self.identifier = identifier
        self.title = title
        self.type = type
        self.isFlatList = isFlatList
        self.components = components
    }

    /// Creates a flat checklist: one untitled component, with the checklist's own identifier, holding `items`.
    public init(
        identifier: String,
        title: String = "",
        type: ChecklistType = .standard,
        items: [ChecklistItem] = []
    ) {
        self.init(
            identifier: identifier,
            title: title,
            type: type,
            isFlatList: true,
            components: [ChecklistComponent(identifier: identifier, items: items)]
        )
    }
}
