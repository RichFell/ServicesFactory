
# Sources 
## Library Architecture 
- One `ServicesFactoryImplementation` object retains services as they are created. Each service retains its repositories.
- Data flow: repositories retrieve raw data from endpoints, local persistence, or other sources, then use builders to decode it into public models. Services take repository models, apply caching and business logic, and return the final data to clients.
- Each service declares a public protocol conforming to `Service`. The concrete implementation is `internal` by default and conforms to that protocol.
- Service implementations go in `Services/`. The `Services` container and `ServicesFactory` go in `ServiceFactory/`.
- Builders default to nested `Decodable` structs that the raw data is decoded into, then map those structs to the public model type. Public models are not `Decodable` by default.
