//
//  ChecklistService.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/15/26.
//

/// A service that retrieves and edits checklists, their components, and their items.
///
/// Nothing is shared between checklists. To reuse a checklist or component, copy it: the copy has
/// its own items, so editing or completing one never affects another.
public protocol ChecklistService: Service {
    /// Streams all available checklists.
    ///
    /// Each subscription immediately receives the current checklists, then a new value after every
    /// change made through this service. The stream finishes with an error if loading fails.
    func allChecklists() -> AsyncThrowingStream<[Checklist], any Error>

    /// Creates a checklist with its components and items.
    ///
    /// - Parameter checklist: The checklist to create.
    /// - Throws: ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when a flat checklist
    ///   doesn't have exactly one component.
    func createChecklist(_ checklist: Checklist) async throws

    /// Updates a checklist's title, type and flat setting. Its components are managed with the component functions.
    ///
    /// - Parameter checklist: The checklist carrying the new values.
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist, or
    ///   ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when making it flat while it
    ///   doesn't have exactly one component.
    func updateChecklist(_ checklist: Checklist) async throws

    /// Deletes a checklist with its components and items.
    ///
    /// - Parameter identifier: The identifier of the checklist to delete. Does nothing if it does not exist.
    func deleteChecklist(identifier: String) async throws

    /// Creates a new checklist from an existing one, copying its type, components and items.
    ///
    /// The copy has new identifiers throughout and nothing completed. Later changes to either checklist
    /// do not affect the other.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the checklist to copy.
    ///   - title: The title of the new checklist.
    /// - Returns: The new checklist.
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist.
    func copyChecklist(identifier: String, title: String) async throws -> Checklist

    /// Adds a component, with its items, to the end of a checklist.
    ///
    /// - Parameters:
    ///   - component: The component to add.
    ///   - checklistIdentifier: The identifier of the checklist to add it to.
    /// - Throws: ``ChecklistError/checklistNotFound(identifier:)`` when the checklist does not exist, or
    ///   ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when it is flat.
    func addComponent(_ component: ChecklistComponent, toChecklistWithIdentifier checklistIdentifier: String) async throws

    /// Updates a component's title. Its items are managed with the item functions.
    ///
    /// - Parameter component: The component carrying the new title.
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` when the component does not exist.
    func updateComponent(_ component: ChecklistComponent) async throws

    /// Deletes a component and its items.
    ///
    /// - Parameter identifier: The identifier of the component to delete. Does nothing if it does not exist.
    /// - Throws: ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when it is the only
    ///   component of a flat checklist.
    func deleteComponent(identifier: String) async throws

    /// Adds a copy of a component, with its items, to the end of another checklist.
    ///
    /// The copy has new identifiers and nothing completed.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the component to copy.
    ///   - checklistIdentifier: The identifier of the checklist to add the copy to.
    /// - Returns: The new component.
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)``, ``ChecklistError/checklistNotFound(identifier:)``,
    ///   or ``ChecklistError/flatChecklistRequiresOneComponent(identifier:)`` when the checklist is flat.
    func copyComponent(identifier: String, toChecklistWithIdentifier checklistIdentifier: String) async throws -> ChecklistComponent

    /// Adds an item to the end of a component.
    ///
    /// - Parameters:
    ///   - item: The item to add.
    ///   - componentIdentifier: The identifier of the component to add it to.
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` when the component does not exist.
    func addItem(_ item: ChecklistItem, toComponentWithIdentifier componentIdentifier: String) async throws

    /// Updates an item's title, weight, price, image and completion.
    ///
    /// - Parameter item: The item carrying the new values.
    /// - Throws: ``ChecklistError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ChecklistItem) async throws

    /// Marks an item completed or not completed.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item.
    ///   - isCompleted: Whether the item is completed.
    /// - Throws: ``ChecklistError/itemNotFound(identifier:)`` when the item does not exist.
    func setItem(identifier: String, isCompleted: Bool) async throws

    /// Deletes an item.
    ///
    /// - Parameter identifier: The identifier of the item to delete. Does nothing if it does not exist.
    func deleteItem(identifier: String) async throws

    /// Moves an item to a new position within a component.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the item to move.
    ///   - componentIdentifier: The identifier of the component containing the item.
    ///   - position: The new zero-based index, clamped to the component's bounds.
    /// - Throws: ``ChecklistError/componentNotFound(identifier:)`` or
    ///   ``ChecklistError/itemNotFound(identifier:)`` when either does not exist.
    func moveItem(identifier: String, inComponentWithIdentifier componentIdentifier: String, to position: Int) async throws
}
