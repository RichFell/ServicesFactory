/// The application's shared registry of service instances.
///
/// Register a concrete implementation for each ``ServiceType`` before
/// requesting it. Registered instances are retained and reused.
public actor Services: ServicesFactory {
    private var registeredServices: [ServiceType: any Service] = [:]

    /// Creates an empty service registry.
    public init() {}

    /// Returns the registered implementation for `serviceType`.
    public func service<ServiceImplementation: Service>(
        for serviceType: ServiceType
    ) async -> ServiceImplementation {
        if let service = registeredServices[serviceType] as? ServiceImplementation {
            return service
        }
        var newService: ServiceImplementation?
        switch serviceType {
        case .list:
            newService = ListServiceImplementation() as? ServiceImplementation
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
