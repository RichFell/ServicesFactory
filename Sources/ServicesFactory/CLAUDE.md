# Sources/ServicesFactory
## Architecture
- One `ServicesFactoryImplementation` object creates and retains services and owns their lifecycle. Each service retains the repositories it depends on.
- Data flow: repositories retrieve raw data from endpoints, local persistence, or other sources, then use builders to decode it into public models. Services take repository models, apply caching and business logic, and return the final data to clients.

### Services
- Each service declares a public protocol conforming to `Service`. The concrete implementation is `internal` by default and conforms to that protocol.

### Builders
- Builders default to nested `Decodable` structs that the raw data is decoded into, then map those structs to the public model type. Public models are not `Decodable` by default.
## Testing
- Every new concrete `class` needs tests verifying its behavior, added to the relevant test target alongside the implementation.

