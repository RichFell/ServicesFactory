//
//  Service.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A service that can be supplied by a ``ServicesFactory``.
public protocol Service: Sendable {
    /// The type under which a ``ServicesFactory`` registers and supplies this service.
    var type: ServiceType { get }
}
