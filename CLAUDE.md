# ServicesFactory

Swift 6 package providing a service-layer library with networking and local persistence.

## Commands
- Build and test through the Xcode MCP tools (`BuildProject`, `RunAllTests`, `RunSomeTests`).
- CLI fallback for the package: `swift build` and `swift test`.

## Environment
- Swift 6 with strict concurrency checking.
- Swift Package Manager only. Do not add third-party libraries without explicit discussion. Approved dependencies are listed in `Package.swift`.

## Code Style
- One top-level `struct`, `class`, or `enum` per Swift file.
- Files under 300 lines; suggest splitting any file that exceeds this.
- Functions under 30 lines and single-responsibility.
- Add `Logger` statements (`os` framework) to complex async flows such as networking.
- Documentation should be added to public functions and prefer documentation on protocol declaration where applicable
- Nested types should be moved to the bottom of the files they are declared in.
- Functions with more than 3 arguments should put each argument on their own line.

## Testing
- Every new concrete `class` needs tests verifying its behavior, added to the relevant test target alongside the implementation.

## Token Efficiencies
- Search first, then read only the lines you need.
- Run the narrowest test first (`-only-testing:` or `--filter`). Run the full suite once, at the end.
- Before adding code, check whether this codebase, the Swift standard library, or an Apple framework already solves it. Then write the smallest change that works, without dropping validation or error handling.
- After two failed attempts at the same fix, stop and report what you learned instead of looping.
