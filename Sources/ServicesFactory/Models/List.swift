//
//  List.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A list returned by a ``EventListService``.
///
/// A list is made of one or more ``ListSection``s. A plain checklist is a list with a single
/// untitled section; a larger list can group its items into several titled sections.
public struct List: Sendable {
    /// Identifier for list
    public let identifier: String

    /// Title of the list
    public let title: String

    /// The optional attributes carried by the items in this list. Empty for a plain checklist.
    public let fields: Set<ListField>

    /// The sections of the list, in order.
    public let sections: [ListSection]

    /// Every item of the list, in section order.
    public var items: [ListItem] {
        sections.flatMap(\.items)
    }

    /// Creates a list made of the given sections.
    public init(
        identifier: String = "",
        title: String = "",
        fields: Set<ListField> = [],
        sections: [ListSection]
    ) {
        self.identifier = identifier
        self.title = title
        self.fields = fields
        self.sections = sections
    }

    /// Creates a plain list: one untitled section, with the list's own identifier, holding `items`.
    public init(
        identifier: String = "",
        title: String = "",
        fields: Set<ListField> = [],
        items: [ListItem] = []
    ) {
        self.init(
            identifier: identifier,
            title: title,
            fields: fields,
            sections: [ListSection(identifier: identifier, items: items)]
        )
    }
}
