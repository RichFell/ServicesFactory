//
//  List.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A list returned by a ``ListService``.
public struct List: Sendable {
    /// Identifier for list
    public let identifier: String

    /// Title of the list
    public let title: String

    /// The optional attributes carried by the items in this list. Empty for a plain checklist.
    public let fields: Set<ListField>

    /// The items contained in the list.
    public let items: [ListItem]

    /// Creates a list model with the given items.
    public init(
        identifier: String = "",
        title: String = "",
        fields: Set<ListField> = [],
        items: [ListItem] = []
    ) {
        self.identifier = identifier
        self.title = title
        self.fields = fields
        self.items = items
    }
}
