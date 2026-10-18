//
//  ChecklistServiceImplementation.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// The default ``ChecklistService`` implementation.
///
/// Reads and edits checklists through the ``Dependency/localCache`` repository.
final class ChecklistServiceImplementation: ChecklistService {
    let type: ServiceType = .checklist

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
    }

    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error> {
        dependency.localCache.allChecklists()
    }

    func createChecklist(_ checklist: Checklist) async throws {
        try await dependency.localCache.createChecklist(checklist)
    }

    func updateChecklist(_ checklist: Checklist) async throws {
        try await dependency.localCache.updateChecklist(checklist)
    }

    func deleteChecklist(identifier: String) async throws {
        try await dependency.localCache.deleteChecklist(identifier: identifier)
    }

    func copyChecklist(identifier: String, title: String) async throws -> Checklist {
        try await dependency.localCache.copyChecklist(identifier: identifier, title: title)
    }

    func addComponent(_ component: ChecklistComponent, toChecklistWithIdentifier checklistIdentifier: String) async throws {
        try await dependency.localCache.addComponent(component, toChecklistWithIdentifier: checklistIdentifier)
    }

    func updateComponent(_ component: ChecklistComponent) async throws {
        try await dependency.localCache.updateComponent(component)
    }

    func deleteComponent(identifier: String) async throws {
        try await dependency.localCache.deleteComponent(identifier: identifier)
    }

    func copyComponent(identifier: String, toChecklistWithIdentifier checklistIdentifier: String) async throws -> ChecklistComponent {
        try await dependency.localCache.copyComponent(
            identifier: identifier,
            toChecklistWithIdentifier: checklistIdentifier
        )
    }

    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws {
        try await dependency.localCache.addItem(item, toComponentWithIdentifier: componentIdentifier)
    }

    func updateItem(_ item: ChecklistItem) async throws {
        try await dependency.localCache.updateItem(item)
    }

    func setItem(identifier: String, isCompleted: Bool) async throws {
        try await dependency.localCache.setItem(identifier: identifier, isCompleted: isCompleted)
    }

    func deleteItem(identifier: String) async throws {
        try await dependency.localCache.deleteItem(identifier: identifier)
    }

    func moveItem(identifier: String, inComponentWithIdentifier componentIdentifier: String, to position: Int) async throws {
        try await dependency.localCache.moveItem(
            identifier: identifier,
            inComponentWithIdentifier: componentIdentifier,
            to: position
        )
    }
}

extension ChecklistServiceImplementation {
    /// The collaborators a ``ChecklistServiceImplementation`` needs.
    struct Dependency: Sendable {
        /// The repository holding locally cached checklists, and applying edits to them.
        let localCache: ChecklistWritableRepository

        init(localCache: ChecklistWritableRepository) {
            self.localCache = localCache
        }

        /// A dependency backed by a ``SQLiteDatabase`` at `databaseLocation`.
        static func live(databaseLocation: SQLiteDatabase.Location) throws -> Dependency {
            let database = try SQLiteDatabase(location: databaseLocation)
            return Dependency(localCache: ChecklistLocalCacheRepository(database: database))
        }
    }
}
