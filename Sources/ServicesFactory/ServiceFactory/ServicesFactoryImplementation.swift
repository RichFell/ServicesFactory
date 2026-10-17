//
//  ServicesFactoryImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The application's shared registry of service instances.
///
/// Register a concrete implementation for each ``ServiceType`` before
/// requesting it. Registered instances are retained and reused.
public actor ServicesFactoryImplementation: ServicesFactory {
    private var registeredServices: [ServiceType: any Service] = [:]

    private let databaseLocation: SQLiteDatabase.Location

    /// Creates an empty service registry whose services cache to the default on-disk database.
    public init() {
        self.databaseLocation = .applicationSupport(fileName: "ServicesFactory.sqlite")
    }

    /// Creates an empty service registry whose services cache to `databaseLocation`.
    init(databaseLocation: SQLiteDatabase.Location) {
        self.databaseLocation = databaseLocation
    }

    /// Returns the registered implementation for `serviceType`.
    public func service<Requested: Sendable>(
        for serviceType: ServiceType
    ) async -> Requested {
        let service = registeredServices[serviceType] ?? makeService(for: serviceType)
        guard let requested = service as? Requested else {
            preconditionFailure("The \(serviceType) service is not a \(Requested.self)")
        }
        registeredServices[serviceType] = service
        return requested
    }

    private func makeService(for serviceType: ServiceType) -> any Service {
        switch serviceType {
        case .eventList:
            do {
                let dependency = try EventListServiceImplementation.Dependency.live(databaseLocation: databaseLocation)
                return EventListServiceImplementation(dependency: dependency)
            } catch {
                preconditionFailure("Failed to open the local cache: \(error)")
            }
        }
    }
}
