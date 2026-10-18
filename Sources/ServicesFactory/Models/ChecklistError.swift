//
//  ChecklistError.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An error thrown by a ``ChecklistService`` when a request names something that does not exist or breaks a rule.
public enum ChecklistError: Error, Equatable, Sendable {
    /// No checklist has the given identifier.
    case checklistNotFound(identifier: String)

    /// No component has the given identifier.
    case componentNotFound(identifier: String)

    /// No item has the given identifier, or it is not in the given component.
    case itemNotFound(identifier: String)

    /// A flat checklist must hold exactly one component, so the request would add or remove one.
    case flatChecklistRequiresOneComponent(identifier: String)
}
