# ServicesFactory

Swift 6 package (`Sources/`, `Tests/`) providing a service-layer networking library, plus an iOS demo app (`DemoApp/`).

## Commands
- Build and test through the Xcode MCP tools (`BuildProject`, `RunAllTests`, `RunSomeTests`).
- CLI fallback for the package: `swift build` and `swift test`.

## Environment
- Swift 6 with strict concurrency checking.
- Swift Package Manager only. Do not add third-party libraries without explicit discussion.

## Library Architecture (`Sources/AsyncNetworkSession/`)
- One `ServicesFactoryImplementation` object retains services as they are created. Each service retains its repositories.
- Data flow: repositories retrieve raw data from endpoints, local persistence, or other sources, then use builders to decode it into public models. Services take repository models, apply caching and business logic, and return the final data to clients.
- Each service declares a public protocol conforming to `Service`. The concrete implementation is `internal` by default and conforms to that protocol.
- Service implementations go in `Services/`. The `Services` container and `ServicesFactory` go in `ServiceFactory/`.
- Builders default to nested `Decodable` structs that the raw data is decoded into, then map those structs to the public model type. Public models are not `Decodable` by default.

## Code Style
- One top-level `struct`, `class`, or `enum` per Swift file.
- Files under 300 lines; suggest splitting any file that exceeds this.
- Functions under 30 lines and single-responsibility.
- Add `Logger` statements (`os` framework) to complex async flows such as networking.
- Documentation should be added to public functions and prefer documentation on protocol declaration where applicable
- Nested types should be moved to the bottom of the files they are declared in.

## Testing
- Every new concrete `class` needs tests verifying its behavior, added to the relevant test target alongside the implementation.
## Xcode Project Files
- Create Swift files on disk. Do not hand-edit `.pbxproj` files.

## Known Gotchas


## Token Efficiencies

- Search first, then read only the lines you need. Don't re-read a file you already have unless it changed.
- Run the narrowest test first (`-only-testing:` or `--filter`). Run the full suite once, at the end.
- Wait inside one command (`gh run watch`, `gh pr checks --watch`, an `until` loop) instead of repeated sleep-and-check turns.
- Inspect the Simulator through its accessibility tree (for example, the RocketSim CLI). Take a screenshot only to verify visuals.
- Load a skill only when the task needs it. Never load two skills that cover the same framework.
- Give search and exploration subagents a small, fast model. Keep the main model for decisions and edits.
- Before adding code, check whether this codebase, the Swift standard library, or an Apple framework already solves it. Then write the smallest change that works, without dropping validation, error handling, or accessibility.
- Lead with the result. Skip restating the plan and narrating tool calls, but keep sentences complete.
- After two failed attempts at the same fix, stop and report what you learned instead of looping.
- Delegate self-contained searches and investigations to a subagent so their reads stay out of this conversation. When the user switches to an unrelated task, suggest a new chat with a short handoff note.
