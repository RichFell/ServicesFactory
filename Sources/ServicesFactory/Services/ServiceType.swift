//
//  ServiceType.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// Identifies a service available from a ``ServicesFactory``.
public enum ServiceType: Hashable, Sendable {
    /// The service responsible for retrieving and editing checklists.
    case checklist
}
