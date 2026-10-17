---
description: Add a new function to a Service, wiring it through the repository, builder, and local database as needed
argument-hint: [optional service name]
---

Add a new function to an existing Service. Follow the steps in order and respect `CLAUDE.md` code style (documentation on protocol declarations, functions under 30 lines, more than 3 arguments one per line, `Logger` in complex async flows, Swift 6 strict concurrency).

## 1. Gather requirements

Use `AskUserQuestion` for anything not already supplied in `$ARGUMENTS`. Collect:

1. **Service name**: choose from the existing services in `Sources/ServicesFactory/Services/` (protocols conforming to `Service`).
2. **Function name**: camelCase.
3. **Arguments and their types**: name and type for each, or none.
4. **Async**: does the function use `async`?
5. **Throws**: does the function `throws`?
6. **Return type**: a type, or `Void`.

Confirm the full signature with the user before editing anything.

## 2. Service protocol and implementation

1. Add the function to the service protocol with a documentation comment (summary, `- Parameter`, `- Returns`, `- Throws` where applicable).
2. Add the function to the `internal` implementation class. Delegate to the repository once step 3 has determined which repository function to call.
3. Update `Tests/Mocks` so any mock of the service conforms to the protocol.

## 3. Repository

1. Read the repository protocol(s) the service depends on and search for existing functions that could satisfy the new function (same or compatible return type, or a result that can be filtered or mapped).
2. If one or more candidates exist, use `AskUserQuestion` to ask whether to reuse each candidate, showing its signature.
3. If none match, or the user declines reuse, add a new function to the repository protocol (documented) and its implementation.
4. Keep any local cache repository in sync, if the repository has one.

## 4. Builder (decoding)

1. Find the builder(s) the repository uses for the return type.
2. If an existing nested `Decodable` struct or builder function already decodes the needed data, reuse it.
3. Otherwise add new decoding logic following the project convention: a nested `Decodable` struct (at the bottom of the file) mapped to the public model. Public models are not `Decodable` by default.
4. If a new builder type is needed, put it in its own file under `Builders/`.

## 5. Local database

Check `Sources/ServicesFactory/Database/` (`SQLiteDatabase`, `SQLiteDatabase+Migrations`, and `DatabaseModel/` records) to decide whether the new function needs persistence support:

- Does an existing query or record already cover the data? If so, reuse it.
- Does the function need a new query, filter, or write method on `SQLiteDatabase`? Add it.
- Does it need new tables or columns? Add a new migration (never edit an existing one) and the matching record type in `DatabaseModel/` plus a record builder under `Builders/`.
- If the function is not data-backed (for example it is purely network or computed), state that no database change is needed.

Report what you found and ask the user before adding any migration.

## 6. Tests

- Add or update tests in the relevant `Tests/Tests` files for every changed or new concrete class and function (service, repository, builder, database).
- Run the narrowest tests first with `RunSomeTests`, then `BuildProject` and `RunAllTests` once at the end.

## 7. Summary

List the files changed and any decisions made (reused vs. new repository function, reused vs. new decoding, database changes or none). Do not commit unless asked.
