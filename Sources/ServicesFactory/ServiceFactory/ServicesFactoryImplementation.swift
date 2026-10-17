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
    public func service<ServiceImplementation: Service>(
        for serviceType: ServiceType
    ) async -> ServiceImplementation {
        if let service = registeredServices[serviceType] as? ServiceImplementation {
            return service
        }
        var newService: ServiceImplementation?
        switch serviceType {
        case .eventList:
            do {
                let dependency = try EventListServiceImplementation.Dependency.live(databaseLocation: databaseLocation)
                newService = EventListServiceImplementation(dependency: dependency) as? ServiceImplementation
            } catch {
                preconditionFailure("Failed to open the local cache: \(error)")
            }
        }
        guard let newService else {
            preconditionFailure("Failed to create a service")
        }
        registeredServices[serviceType] = newService
        return newService
    }
    
    public func register<ServiceImplementation: Service>(
        _ service: ServiceImplementation,
        for serviceType: ServiceType
    ) {
        registeredServices[serviceType] = service
    }
}
