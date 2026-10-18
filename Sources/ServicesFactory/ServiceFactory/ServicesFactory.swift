//
//  ServicesFactory.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// Supplies services based on their ``ServiceType``.
///
/// A conforming factory maps each service type to its corresponding concrete
/// service implementation, which clients never need to reference.
public protocol ServicesFactory: Sendable {
    /// Returns the service associated with `serviceType`.
    ///
    /// Clients request the service by its protocol type, for example
    /// `factory.service(for: .checklist) as ChecklistService`.
    func service<Requested: Sendable>(
        for serviceType: ServiceType
    ) async -> Requested
}
