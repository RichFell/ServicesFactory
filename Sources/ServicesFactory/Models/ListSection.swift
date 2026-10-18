//
//  ListSection.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An ordered group of items within a ``List``, such as "Kitchen" in a packing list.
public struct ListSection: Sendable {
    /// The unique identifier of the section.
    public let identifier: String
    /// The display title of the section. Empty for a list that is a single group of items.
    public let title: String
    /// The items in the section, in order.
    public let items: [ListItem]

    /// Creates a section with the given identifier, title and items.
    public init(
        identifier: String,
        title: String = "",
        items: [ListItem] = []
    ) {
        self.identifier = identifier
        self.title = title
        self.items = items
    }
}
