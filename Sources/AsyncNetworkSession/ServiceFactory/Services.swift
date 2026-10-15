import Foundation

/// The application's shared registry of service instances.
///
/// Register a concrete implementation for each ``ServiceType`` before
/// requesting it. Registered instances are retained and reused.
public final class Services: ServicesFactory, @unchecked Sendable {
    private let lock = NSLock()
    private var registeredServices: [ServiceType: any Service] = [:]

    /// Creates an empty service registry.
    public init() {}

    /// Registers `service` as the implementation for `serviceType`.
    public func register<ServiceImplementation: Service>(
        _ service: ServiceImplementation,
        for serviceType: ServiceType
    ) {
        lock.lock()

        registeredServices[serviceType] = service
        
        lock.unlock()
    }

    /// Returns the registered implementation for `serviceType`.
    public func service<ServiceImplementation: Service>(
        for serviceType: ServiceType
    ) -> ServiceImplementation {
        lock.lock()
        defer { lock.unlock() }

        guard let service = registeredServices[serviceType] as? ServiceImplementation else {
            preconditionFailure("No matching service is registered for \\(serviceType).")
        }

        return service
    }
}
