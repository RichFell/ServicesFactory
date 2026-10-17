//
//  ServicesFactory.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// Supplies services based on their ``ServiceType``.
///
/// A conforming factory maps each service type to its corresponding concrete
/// service implementation.
public protocol ServicesFactory: Sendable {
    /// Returns the service associated with `serviceType`.
    func service<ServiceImplementation: Service>(
        for serviceType: ServiceType
    ) async -> ServiceImplementation
}
