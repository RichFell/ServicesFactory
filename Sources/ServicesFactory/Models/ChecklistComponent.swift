//
//  ChecklistComponent.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An ordered group of items within a ``Checklist``, such as "Kitchen" in a packing checklist.
public struct ChecklistComponent: Sendable {
    /// The unique identifier of the component.
    public let identifier: String
    /// The display title of the component. Empty for a flat checklist.
    public let title: String
    /// The items in the component, in order.
    public let items: [ChecklistItem]

    /// Creates a component with the given identifier, title and items.
    public init(
        identifier: String,
        title: String = "",
        items: [ChecklistItem] = []
    ) {
        self.identifier = identifier
        self.title = title
        self.items = items
    }
}
