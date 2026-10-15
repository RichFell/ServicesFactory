
# iOS Project Rules & Guidelines

## 🛠️ Technology Stack & Environment
- **Language:** Swift 6 (Strict concurrency checking)
- **Library Architecture (`Sources/` only):** Use a service-layer architecture with one main `Services` object that retains services as they are created.
- **Demo App Architecture (`DemoApp/` only):** Use the MVVM-C pattern. Keep SwiftUI views focused on presentation, place presentation state and logic in view models, and use coordinators for navigation and flow orchestration.
- **Demo App Folder Organization (`DemoApp/` only):** Place views in `Views/`, view models in `ViewModels/`, models in `Models/`, and service implementations in `Services/`. Each type belongs in the folder that matches its responsibility.
- **Library Folder Organization (`Sources/` only):** Place service implementations in `Services/`. Place the `Services` container and `ServicesFactory` in `ServiceFactory/`.
- **Dependency Manager:** Swift Package Manager (SPM) only. Avoid adding third-party libraries without explicit discussion.

## ⚠️ Critical iOS & Xcode Safety Rules
1. **When adding `.pbxproj` files:** AI must create swift files on disk
2. Canvas Previews:** Every new SwiftUI view must include a `#Preview` block using static mock data. Do NOT trigger live network or database fetches in previews.
3. **One Type Per File:** Each `struct`, `class`, or `enum` must reside in its own dedicated Swift file. Avoid defining multiple top-level types together.

## 🧪 Testing Requirements
- **Concrete Classes:** Every new concrete `class` must include tests that verify its functional behavior. Add those tests to the relevant test target with the implementation.

## 📏 Code Architecture Limits
- **File Length:** Maximum 300 lines per file. Suggest refactoring/splitting if a file exceeds this.
- **Function Length:** Maximum 30 lines per function. Keep functions single-responsibility.
- **State Management:** Prefer `@State` and `@Observable` macros. Avoid legacy `ObservableObject` unless targeting older iOS versions.

## 📝 iOS & Platform Gotchas
- Always add `Logger` statements from the native `os` framework for complex async flows (e.g., camera, networking).
- Keep platform-specific layout limitations documented here as they arise (e.g., specific iOS API bugs or view modifier ordering).
