//
//  EventListError.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An error thrown by an ``EventListService`` when a requested list, section, item, event or run does not exist.
public enum EventListError: Error, Equatable, Sendable {
    /// No list has the given identifier, or it is not in the given run.
    case listNotFound(identifier: String)

    /// No section has the given identifier.
    case sectionNotFound(identifier: String)

    /// No item has the given identifier, or it is not in the given section or list.
    case itemNotFound(identifier: String)

    /// No event has the given identifier.
    case eventNotFound(identifier: String)

    /// No run has the given identifier.
    case runNotFound(identifier: String)
}
