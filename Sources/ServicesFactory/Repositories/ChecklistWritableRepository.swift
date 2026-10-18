//
//  ChecklistWritableRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// A ``ChecklistRepository`` that can also create, edit, copy and delete checklists, components and items.
///
/// Nothing is shared: every component belongs to one checklist and every item to one component.
/// Reusing a checklist or component copies it, so edits and completion never leak between them.
protocol ChecklistWritableRepository: ChecklistRepository {
    /// Stores a new checklist with its components and items.
    ///
    /// - Throws: ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when a flat checklist
    ///   doesn't have exactly one component.
    func createChecklist(_ checklist: Checklist) async throws

    /// Updates the title, type and flat setting of the checklist with the same identifier. Components are left unchanged.
    ///
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist, or
    ///   ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when making a checklist flat that
    ///   doesn't have exactly one component.
    func updateChecklist(_ checklist: Checklist) async throws

    /// Deletes the checklist with its components and items. Does nothing if the checklist is missing.
    func deleteChecklist(identifier: String) async throws

    /// Stores a copy of a checklist titled `title`, with new identifiers throughout and nothing completed.
    ///
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist.
    /// - Returns: The copy.
    func copyChecklist(identifier: String, title: String) async throws -> Checklist

    /// Adds `component`, with its items, to the end of a checklist.
    ///
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist, or
    ///   ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when it is flat.
    func addComponent(_ component: ChecklistComponent, toChecklistWithIdentifier checklistIdentifier: String) async throws

    /// Updates the title of the component with the same identifier. Its items are left unchanged.
    ///
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` when the component does not exist.
    func updateComponent(_ component: ChecklistComponent) async throws

    /// Deletes the component and its items. Does nothing if the component is missing.
    ///
    /// - Throws: ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when the component is
    ///   the only one of a flat checklist.
    func deleteComponent(identifier: String) async throws

    /// Adds a copy of a component, with new identifiers and nothing completed, to the end of another checklist.
    ///
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)``, ``ChecklistError/checklistNotFound(identifier:)``,
    ///   or ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when the target is flat.
    /// - Returns: The copy.
    func copyComponent(
        identifier: String,
        toChecklistWithIdentifier checklistIdentifier: String
    ) async throws -> ChecklistComponent

    /// Adds `item` to the end of a component.
    ///
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` when the component does not exist.
    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws

    /// Updates the item with the same identifier, including its completion.
    ///
    /// - Throws: ``ChecklistError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ChecklistItem) async throws

    /// Marks an item completed or not completed.
    ///
    /// - Throws: ``ChecklistError/itemNotFound(identifier:)`` when the item does not exist.
    func setItem(identifier: String, isCompleted: Bool) async throws

    /// Deletes the item. Does nothing if the item is missing.
    func deleteItem(identifier: String) async throws

    /// Moves an item to `position` within a component. The position is clamped to the component's bounds.
    ///
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` or ``ChecklistError/itemNotFound(identifier:)``.
    func moveItem(identifier: String, inComponentWithIdentifier componentIdentifier: String, to position: Int) async throws
}
