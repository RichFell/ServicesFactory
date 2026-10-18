//
//  EventListWritableRepository.swift
//  ServicesFactory
//
//  Created by Rich Fellure on 10/17/26.
//

import Foundation

/// An ``EventListRepository`` that can also create, edit and delete lists, items, events and runs.
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

    /// Deletes the item and its links to every list. Runs keep their own copy of the item.
    func deleteItem(identifier: String) async throws

    /// Moves an item to `position` within a list. The position is clamped to the list's bounds.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` or ``EventListError/itemNotFound(identifier:)``.
    func moveItem(identifier: String, inListWithIdentifier listIdentifier: String, to position: Int) async throws

    /// Stores a new event that uses the already stored lists named by `event.lists`, in order.
    ///
    /// - Throws: ``EventListError/listNotFound(identifier:)`` when a list does not exist.
    func createEvent(_ event: Event) async throws

    /// Updates the title and lists of the event with the same identifier. Existing runs are unchanged.
    ///
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` or ``EventListError/listNotFound(identifier:)``.
    func updateEvent(_ event: Event) async throws

    /// Deletes the event and all of its runs. Does nothing if the event is missing.
    func deleteEvent(identifier: String) async throws

    /// Starts a run of an event, snapshotting the event's lists, fields and items as they are now.
    ///
    /// - Throws: ``EventListError/eventNotFound(identifier:)`` when the event does not exist.
    /// - Returns: The new run.
    func startRun(
        ofEventWithIdentifier eventIdentifier: String,
        identifier: String,
        startedAt: Date
    ) async throws -> EventRun

    /// Marks an item of a run's snapshot as completed or not completed.
    ///
    /// - Throws: ``EventListError/runNotFound(identifier:)`` or
    ///   ``EventListError/itemNotFound(identifier:)`` when the item is not in the run.
    func setItem(
        identifier: String,
        isCompleted: Bool,
        inRunWithIdentifier runIdentifier: String
    ) async throws

    /// Marks a run as completed (recording `date`) or reopens it.
    ///
    /// - Throws: ``EventListError/runNotFound(identifier:)`` when the run does not exist.
    func setRun(
        identifier: String,
        isComplete: Bool,
        at date: Date
    ) async throws

    /// Deletes a run and its snapshot. Does nothing if the run is missing.
    func deleteRun(identifier: String) async throws
}
