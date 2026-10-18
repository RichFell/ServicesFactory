# ServicesFactory

Swift 6 package providing a service-layer library with networking and local persistence.

## Commands
- Build and test through the Xcode MCP tools (`BuildProject`, `RunAllTests`, `RunSomeTests`).
- CLI fallback for the package: `swift build` and `swift test`.

## Environment
- Swift 6 with strict concurrency checking.
- Swift Package Manager only. Do not add third-party libraries without explicit discussion. Approved dependencies are listed in `Package.swift`.

## Code Style
- Keep functions under 30 lines. Flag files over 300 lines and propose a split.
- Add `Logger` statements (`os` framework) to complex async flows such as networking.
- Documentation should be added to public functions
- Don't declare an extension of a type in the same file as the type itself; put members in the type body. 
- Nested types should be moved to the bottom of the files they are declared in.
- Functions with more than 2 arguments should put each argument on their own line at call site, as well as when declared.
- Protocol-oriented pattern in regards to references of types allowing easy injection of different types. 
- Omit `self` unless required. Omit `any` for protocol-typed parameters. Use `some` or `any` only when the compiler requires it.
