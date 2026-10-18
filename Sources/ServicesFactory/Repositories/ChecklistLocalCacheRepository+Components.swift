//
//  ChecklistLocalCacheRepository+Components.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import SQLiteData

// Component operations of ``ChecklistLocalCacheRepository``.
extension ChecklistLocalCacheRepository {
    func addComponent(
        _ component: ChecklistComponent,
        toChecklistWithIdentifier checklistIdentifier: String
    ) async throws {
        try await database.transaction { db in
            let position = try Self.requireOpenChecklist(checklistIdentifier, in: db)
            try Self.insert(component, at: position, inChecklist: checklistIdentifier, in: db)
        }
        logger.debug("Added component \(component.identifier) to checklist \(checklistIdentifier)")
    }

    func updateComponent(_ component: ChecklistComponent) async throws {
        try await database.transaction { db in
            guard var record = try ChecklistComponentRecord.find(component.identifier).fetchOne(db) else {
                throw ChecklistError.componentNotFound(identifier: component.identifier)
            }
            record.title = component.title
            try ChecklistComponentRecord.update(record).execute(db)
        }
        logger.debug("Updated component \(component.identifier)")
    }

    func deleteComponent(identifier: String) async throws {
        try await database.transaction { db in
            guard let record = try ChecklistComponentRecord.find(identifier).fetchOne(db) else { return }
            let checklist = try ChecklistRecord.find(record.checklistID).fetchOne(db)
            guard checklist?.isFlatList != true else {
                throw ChecklistError.flatChecklistRequiresOneComponent(identifier: record.checklistID)
            }
            // Items cascade.
            try ChecklistComponentRecord.where { $0.id.eq(identifier) }.delete().execute(db)
        }
        logger.debug("Deleted component \(identifier)")
    }

    func copyComponent(
        identifier: String,
        toChecklistWithIdentifier checklistIdentifier: String
    ) async throws -> ChecklistComponent {
        let builder = builder
        let copy = try await database.transaction { db in
            let position = try Self.requireOpenChecklist(checklistIdentifier, in: db)
            let components = try self.fetchChecklists(in: db).flatMap(\.components)
            guard let original = components.first(where: { $0.identifier == identifier }) else {
                throw ChecklistError.componentNotFound(identifier: identifier)
            }
            let copy = builder.copy(of: original)
            try Self.insert(copy, at: position, inChecklist: checklistIdentifier, in: db)
            return copy
        }
        logger.debug("Copied component \(identifier) to checklist \(checklistIdentifier) as \(copy.identifier)")
        return copy
    }

    // MARK: - Helpers

    /// Checks that the checklist exists and can take another component.
    ///
    /// - Returns: The position a new component takes at the end of the checklist.
    private static func requireOpenChecklist(_ identifier: String, in db: Database) throws -> Int {
        guard let checklist = try ChecklistRecord.find(identifier).fetchOne(db) else {
            throw ChecklistError.checklistNotFound(identifier: identifier)
        }
        guard !checklist.isFlatList else {
            throw ChecklistError.flatChecklistRequiresOneComponent(identifier: identifier)
        }
        let positions = try ChecklistComponentRecord.where { $0.checklistID.eq(identifier) }.fetchAll(db).map(\.position)
        return (positions.max() ?? -1) + 1
    }

    /// Inserts `component` and its items at `position` in the checklist.
    private static func insert(
        _ component: ChecklistComponent,
        at position: Int,
        inChecklist checklistIdentifier: String,
        in db: Database
    ) throws {
        let record = ChecklistComponentRecord(
            id: component.identifier,
            checklistID: checklistIdentifier,
            title: component.title,
            position: position
        )
        let items = component.items.enumerated().map { index, item in
            ChecklistItemRecord(item, componentID: component.identifier, position: index)
        }
        try ChecklistComponentRecord.insert { [record] }.execute(db)
        try ChecklistItemRecord.insert { items }.execute(db)
    }
}
