//
//  EventListError.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An error thrown by an ``EventListService`` when a requested list or item does not exist.
public enum EventListError: Error, Equatable, Sendable {
    /// No list has the given identifier.
    case listNotFound(identifier: String)

    /// No item has the given identifier, or it is not in the given list.
    case itemNotFound(identifier: String)
}
