//
//  EventListWritableRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

/// An ``EventListRepository`` that can also create, edit and delete lists and their items.
///
/// Items are standalone and can belong to several lists. Removing a list or unlinking an item
/// never deletes the other side; only ``deleteItem(identifier:)`` removes an item.
protocol EventListWritableRepository: EventListRepository {
    /// Stores a new list with its fields and items. Items that already exist are linked, not duplicated.
    func createList(_ list: List) async throws

    /// Updates the title and fields of the list with the same identifier. Items are left unchanged.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func updateList(_ list: List) async throws

    /// Deletes the list and its links to items. The items themselves are kept. Does nothing if the list is missing.
    func deleteList(identifier: String) async throws

    /// Adds `item` to the end of a list, creating the item if it is new or updating it if it exists.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when the list does not exist.
    func addItem(_ item: ListItem, toListWithIdentifier listIdentifier: String) async throws

    /// Unlinks an item from a list. The item is kept and stays in its other lists.
    func removeItem(identifier: String, fromListWithIdentifier listIdentifier: String) async throws

    /// Updates the item with the same identifier in every list that contains it.
    ///
    /// - Throws: ``EventListError/itemNotFound(identifier:)`` when the item does not exist.
    func updateItem(_ item: ListItem) async throws

    /// Deletes the item, its links to every list and its completion marks in every event.
    func deleteItem(identifier: String) async throws

    /// Moves an item to `position` within a list. The position is clamped to the list's bounds.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` or ``EventListError/itemNotFound(identifier:)``.
    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws
}
