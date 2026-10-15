# AsyncNetworkSession

Swift 6 package (`Sources/`, `Tests/`) providing a service-layer networking library, plus an iOS demo app (`DemoApp/`).

## Commands
- Build and test through the Xcode MCP tools (`BuildProject`, `RunAllTests`, `RunSomeTests`).
- CLI fallback for the package: `swift build` and `swift test`.

## Environment
- Swift 6 with strict concurrency checking.
- Swift Package Manager only. Do not add third-party libraries without explicit discussion.

## Library Architecture (`Sources/AsyncNetworkSession/`)
- One `Services` object retains services as they are created. Each service retains its repositories.
- Data flow: repositories retrieve raw data from endpoints, local persistence, or other sources, then use builders to decode it into public models. Services take repository models, apply caching and business logic, and return the final data to clients.
- Each service declares a public protocol conforming to `Service`. The concrete implementation is `internal` by default and conforms to that protocol.
- Service implementations go in `Services/`. The `Services` container and `ServicesFactory` go in `ServiceFactory/`.

## Demo App Architecture (`DemoApp/`)
- Use MVVM-C. Views handle presentation only, view models hold presentation state and logic, and coordinators handle navigation and flow orchestration.
- Folders: `Views/`, `ViewModels/`, `Models/`, `Services/`. Put each type in the folder matching its responsibility.
- View models (`ViewModels/`):
  - Declare injected collaborators in a nested `Dependency` struct and accept it in the initializer.
  - Expose nested `Input` and `Output` types. Views and other view models call `Input` functions, which forward events through a `PassthroughSubject` that the view model subscribes to. `Output` exposes publishers for views and other view models to observe.
- Every new SwiftUI view needs a `#Preview` with static mock data. Previews must not trigger live network or database fetches.
- Prefer `@State` and `@Observable`. Use `ObservableObject` only when targeting older iOS versions.

## Code Style
- One top-level `struct`, `class`, or `enum` per Swift file.
- Files under 300 lines; suggest splitting any file that exceeds this.
- Functions under 30 lines and single-responsibility.
- Add `Logger` statements (`os` framework) to complex async flows such as networking.

## Testing
- Every new concrete `class` needs tests verifying its behavior, added to the relevant test target alongside the implementation.

## Xcode Project Files
- Create Swift files on disk. Do not hand-edit `.pbxproj` files.

## Known Gotchas
- Record platform-specific limitations here as they come up, such as iOS API bugs or view modifier ordering issues.
